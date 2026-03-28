"""
NAV Break Detection and Analysis Tool
Capital Management Co. - Fund Governance Simulation

Automates the detection of NAV breaks (discrepancies between internally
calculated NAV and administrator-reported NAV) across the CMC fund range.
Breaks exceeding the agreed tolerance threshold are flagged for investigation.

Fund Universe:
    Global Equity Fund              | IE00B4X9L533
    European Bond Fund              | IE00BK5BQ103
    Multi-Asset Growth Fund         | LU0292097234
    Emerging Markets Fund           | IE00BFYN9Y00
    Real Estate Opportunities       | LU0488316133
    Private Credit Fund             | LU0629460675

Usage:
    python nav_break_analysis.py --input nav_daily_report.csv --output nav_breaks_report.csv
"""

import argparse
import logging
import sys
from datetime import datetime
from pathlib import Path

import pandas as pd

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Default tolerance for NAV breaks (as a percentage, e.g. 0.01 = 0.01%)
DEFAULT_TOLERANCE_PCT = 0.01

# Fund reference data
FUND_UNIVERSE = {
    "IE00B4X9L533": "Global Equity Fund",
    "IE00BK5BQ103": "European Bond Fund",
    "LU0292097234": "Multi-Asset Growth Fund",
    "IE00BFYN9Y00": "Emerging Markets Fund",
    "LU0488316133": "Real Estate Opportunities Fund",
    "LU0629460675": "Private Credit Fund",
}

# Expected CSV columns
REQUIRED_COLUMNS = [
    "fund_id",
    "isin",
    "nav_date",
    "internal_nav",
    "administrator_nav",
    "total_net_assets",
]

# ---------------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Core analysis class
# ---------------------------------------------------------------------------


class NAVBreakAnalyser:
    """Analyses daily NAV data to detect and report breaks against the fund
    administrator's figures.

    Attributes:
        tolerance_pct: The maximum acceptable percentage difference between
            internal and administrator NAV before a break is flagged.
        data: A pandas DataFrame holding the loaded NAV data.
        breaks: A pandas DataFrame holding detected breaks after analysis.
    """

    def __init__(self, tolerance_pct: float = DEFAULT_TOLERANCE_PCT):
        """Initialise the analyser with a tolerance threshold.

        Args:
            tolerance_pct: Break tolerance as a percentage (default 0.01%).
        """
        self.tolerance_pct = tolerance_pct
        self.data: pd.DataFrame = pd.DataFrame()
        self.breaks: pd.DataFrame = pd.DataFrame()
        logger.info(
            "NAVBreakAnalyser initialised with tolerance: %.4f%%",
            self.tolerance_pct,
        )

    def load_data(self, filepath: str) -> pd.DataFrame:
        """Load NAV data from a CSV file.

        Args:
            filepath: Path to the CSV file containing daily NAV data.

        Returns:
            The loaded DataFrame.

        Raises:
            FileNotFoundError: If the CSV file does not exist.
            ValueError: If required columns are missing.
        """
        path = Path(filepath)
        if not path.exists():
            logger.error("File not found: %s", filepath)
            raise FileNotFoundError(f"File not found: {filepath}")

        logger.info("Loading NAV data from: %s", filepath)
        self.data = pd.read_csv(filepath, parse_dates=["nav_date"])

        # Validate required columns are present
        missing = [c for c in REQUIRED_COLUMNS if c not in self.data.columns]
        if missing:
            logger.error("Missing required columns: %s", missing)
            raise ValueError(f"Missing required columns: {missing}")

        # Sort for consistent processing
        self.data.sort_values(["isin", "nav_date"], inplace=True)
        self.data.reset_index(drop=True, inplace=True)

        logger.info(
            "Loaded %d records across %d funds",
            len(self.data),
            self.data["isin"].nunique(),
        )
        return self.data

    def calculate_expected_nav(self) -> pd.DataFrame:
        """Calculate expected NAV based on prior day NAV plus daily return.

        Adds columns for prior-day NAV, daily return, and expected NAV
        to the main data DataFrame.

        Returns:
            The DataFrame with additional calculated columns.
        """
        if self.data.empty:
            logger.warning("No data loaded. Call load_data() first.")
            return self.data

        logger.info("Calculating expected NAV based on prior-day values")

        self.data["prior_day_nav"] = self.data.groupby("isin")[
            "internal_nav"
        ].shift(1)

        self.data["daily_return_pct"] = (
            (self.data["internal_nav"] - self.data["prior_day_nav"])
            / self.data["prior_day_nav"]
            * 100.0
        )

        self.data["expected_nav"] = self.data["prior_day_nav"] * (
            1 + self.data["daily_return_pct"] / 100.0
        )

        return self.data

    def detect_breaks(self) -> pd.DataFrame:
        """Compare internal NAV against administrator NAV and flag breaks.

        A break is flagged when the absolute percentage difference between
        internal_nav and administrator_nav exceeds the configured tolerance.

        Returns:
            A DataFrame containing only the records that breach the tolerance.
        """
        if self.data.empty:
            logger.warning("No data loaded. Call load_data() first.")
            return pd.DataFrame()

        logger.info("Detecting NAV breaks with tolerance: %.4f%%", self.tolerance_pct)

        # Calculate the difference between internal and administrator NAV
        self.data["nav_difference"] = (
            self.data["internal_nav"] - self.data["administrator_nav"]
        )

        self.data["difference_pct"] = (
            self.data["nav_difference"]
            / self.data["administrator_nav"].replace(0, float("nan"))
            * 100.0
        )

        self.data["abs_difference_pct"] = self.data["difference_pct"].abs()

        # Flag breaks exceeding tolerance
        self.data["is_break"] = (
            self.data["abs_difference_pct"] > self.tolerance_pct
        )

        # Extract breaks into a separate DataFrame
        self.breaks = self.data[self.data["is_break"]].copy()

        # Add fund name from reference data
        self.breaks["fund_name"] = self.breaks["isin"].map(FUND_UNIVERSE)

        # Classify severity
        self.breaks["severity"] = self.breaks["abs_difference_pct"].apply(
            self._classify_severity
        )

        break_count = len(self.breaks)
        total_records = len(self.data)
        logger.info(
            "Detected %d breaks out of %d records (%.2f%%)",
            break_count,
            total_records,
            break_count / total_records * 100.0 if total_records > 0 else 0,
        )

        return self.breaks

    @staticmethod
    def _classify_severity(abs_diff_pct: float) -> str:
        """Classify a break by severity based on the percentage difference.

        Args:
            abs_diff_pct: Absolute percentage difference.

        Returns:
            Severity label: 'Low', 'Medium', 'High', or 'Critical'.
        """
        if abs_diff_pct > 1.0:
            return "Critical"
        elif abs_diff_pct > 0.1:
            return "High"
        elif abs_diff_pct > 0.05:
            return "Medium"
        else:
            return "Low"

    def generate_summary(self) -> pd.DataFrame:
        """Generate a summary report of NAV breaks grouped by fund.

        Returns:
            A summary DataFrame with break counts and statistics per fund.
        """
        if self.breaks.empty:
            logger.info("No breaks detected. Summary is empty.")
            return pd.DataFrame(
                columns=[
                    "isin",
                    "fund_name",
                    "total_breaks",
                    "avg_abs_diff_pct",
                    "max_abs_diff_pct",
                    "critical_count",
                    "high_count",
                ]
            )

        logger.info("Generating break summary report")

        summary = (
            self.breaks.groupby(["isin", "fund_name"])
            .agg(
                total_breaks=("is_break", "sum"),
                avg_abs_diff_pct=("abs_difference_pct", "mean"),
                max_abs_diff_pct=("abs_difference_pct", "max"),
                min_nav_date=("nav_date", "min"),
                max_nav_date=("nav_date", "max"),
                critical_count=("severity", lambda x: (x == "Critical").sum()),
                high_count=("severity", lambda x: (x == "High").sum()),
            )
            .reset_index()
        )

        summary["avg_abs_diff_pct"] = summary["avg_abs_diff_pct"].round(6)
        summary["max_abs_diff_pct"] = summary["max_abs_diff_pct"].round(6)

        return summary

    def export_results(self, output_path: str) -> None:
        """Export detected breaks and summary to CSV files.

        Creates two files:
            - {output_path}: Full break details
            - {output_path_stem}_summary.csv: Aggregated summary

        Args:
            output_path: File path for the detailed break report CSV.
        """
        output = Path(output_path)

        if self.breaks.empty:
            logger.info("No breaks to export.")
            # Write an empty file with headers for downstream processes
            pd.DataFrame(columns=REQUIRED_COLUMNS + [
                "nav_difference", "difference_pct", "abs_difference_pct",
                "is_break", "fund_name", "severity"
            ]).to_csv(output, index=False)
            logger.info("Empty break report written to: %s", output)
            return

        # Export detailed breaks
        export_columns = [
            "fund_name",
            "isin",
            "fund_id",
            "nav_date",
            "internal_nav",
            "administrator_nav",
            "nav_difference",
            "difference_pct",
            "abs_difference_pct",
            "severity",
            "total_net_assets",
        ]
        available_columns = [c for c in export_columns if c in self.breaks.columns]
        self.breaks[available_columns].to_csv(output, index=False)
        logger.info("Break details exported to: %s (%d records)", output, len(self.breaks))

        # Export summary
        summary = self.generate_summary()
        summary_path = output.parent / f"{output.stem}_summary.csv"
        summary.to_csv(summary_path, index=False)
        logger.info("Break summary exported to: %s", summary_path)


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments.

    Returns:
        Parsed argument namespace.
    """
    parser = argparse.ArgumentParser(
        description="NAV Break Detection Tool - Capital Management Co."
    )
    parser.add_argument(
        "--input",
        "-i",
        required=True,
        help="Path to the input CSV file (nav_daily_report.csv)",
    )
    parser.add_argument(
        "--output",
        "-o",
        default="nav_breaks_report.csv",
        help="Path for the output break report CSV (default: nav_breaks_report.csv)",
    )
    parser.add_argument(
        "--tolerance",
        "-t",
        type=float,
        default=DEFAULT_TOLERANCE_PCT,
        help=f"Break tolerance in percent (default: {DEFAULT_TOLERANCE_PCT}%%)",
    )
    return parser.parse_args()


def main() -> None:
    """Main execution flow for NAV break detection."""
    args = parse_arguments()

    logger.info("=" * 60)
    logger.info("NAV Break Analysis - Capital Management Co.")
    logger.info("Run date: %s", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    logger.info("=" * 60)

    analyser = NAVBreakAnalyser(tolerance_pct=args.tolerance)

    try:
        # Step 1: Load the NAV data
        analyser.load_data(args.input)

        # Step 2: Calculate expected NAV from prior-day values
        analyser.calculate_expected_nav()

        # Step 3: Detect breaks against administrator data
        breaks = analyser.detect_breaks()

        # Step 4: Generate and display summary
        summary = analyser.generate_summary()
        if not summary.empty:
            logger.info("Break Summary by Fund:")
            for _, row in summary.iterrows():
                logger.info(
                    "  %-40s | Breaks: %3d | Max diff: %.4f%% | Critical: %d",
                    row["fund_name"],
                    row["total_breaks"],
                    row["max_abs_diff_pct"],
                    row["critical_count"],
                )
        else:
            logger.info("No NAV breaks detected. All funds within tolerance.")

        # Step 5: Export results
        analyser.export_results(args.output)

    except FileNotFoundError as e:
        logger.error("Input file error: %s", e)
        sys.exit(1)
    except ValueError as e:
        logger.error("Data validation error: %s", e)
        sys.exit(1)
    except Exception as e:
        logger.error("Unexpected error: %s", e, exc_info=True)
        sys.exit(1)

    logger.info("NAV break analysis complete.")


if __name__ == "__main__":
    main()
