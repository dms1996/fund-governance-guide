"""
Fee Calculation Engine
Capital Management Co. - Fund Governance Simulation

Calculates daily management fee accruals and performance fees (with
high-water mark logic) for the CMC fund range. Validates calculated
fees against expected rates and exports results for reconciliation.

Fund Universe:
    Global Equity Fund              | IE00B4X9L533
    European Bond Fund              | IE00BK5BQ103
    Multi-Asset Growth Fund         | LU0292097234
    Emerging Markets Fund           | IE00BFYN9Y00
    Real Estate Opportunities       | LU0488316133
    Private Credit Fund             | LU0629460675

Usage:
    python fee_calculator.py --nav-file nav_data.csv --fee-schedule fee_schedule.csv --output fee_report.csv
"""

import argparse
import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

import pandas as pd

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

DAYS_IN_YEAR = 365

FUND_UNIVERSE = {
    "IE00B4X9L533": "Global Equity Fund",
    "IE00BK5BQ103": "European Bond Fund",
    "LU0292097234": "Multi-Asset Growth Fund",
    "IE00BFYN9Y00": "Emerging Markets Fund",
    "LU0488316133": "Real Estate Opportunities Fund",
    "LU0629460675": "Private Credit Fund",
}

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Management Fee Calculator
# ---------------------------------------------------------------------------


class ManagementFeeCalculator:
    """Calculates daily management fee accruals for each fund and share class.

    The management fee is accrued daily as:
        daily_accrual = total_net_assets * annual_fee_rate / 365

    Attributes:
        nav_data: DataFrame with daily NAV and TNA figures.
        fee_schedule: DataFrame with fund/share-class fee rates.
        results: DataFrame with calculated daily accruals.
    """

    def __init__(self):
        """Initialise the management fee calculator."""
        self.nav_data: pd.DataFrame = pd.DataFrame()
        self.fee_schedule: pd.DataFrame = pd.DataFrame()
        self.results: pd.DataFrame = pd.DataFrame()

    def load_data(self, nav_filepath: str, fee_schedule_filepath: str) -> None:
        """Load NAV data and fee schedule from CSV files.

        Args:
            nav_filepath: Path to the NAV data CSV.
            fee_schedule_filepath: Path to the fee schedule CSV.

        Raises:
            FileNotFoundError: If either file does not exist.
        """
        for filepath, label in [
            (nav_filepath, "NAV data"),
            (fee_schedule_filepath, "Fee schedule"),
        ]:
            if not Path(filepath).exists():
                raise FileNotFoundError(f"{label} file not found: {filepath}")

        logger.info("Loading NAV data from: %s", nav_filepath)
        self.nav_data = pd.read_csv(nav_filepath, parse_dates=["nav_date"])

        logger.info("Loading fee schedule from: %s", fee_schedule_filepath)
        self.fee_schedule = pd.read_csv(fee_schedule_filepath)

        logger.info(
            "Loaded %d NAV records and %d fee schedule entries",
            len(self.nav_data),
            len(self.fee_schedule),
        )

    def calculate_daily_accruals(self) -> pd.DataFrame:
        """Calculate daily management fee accruals.

        Merges NAV data with the fee schedule and computes the daily accrual
        for each fund/share class combination.

        Returns:
            DataFrame with daily accrual calculations.
        """
        if self.nav_data.empty or self.fee_schedule.empty:
            logger.warning("Data not loaded. Call load_data() first.")
            return pd.DataFrame()

        logger.info("Calculating daily management fee accruals")

        # Merge NAV data with fee schedule on fund_id and share_class
        merged = self.nav_data.merge(
            self.fee_schedule[
                self.fee_schedule["fee_type"] == "Management Fee"
            ],
            on=["fund_id", "share_class"],
            how="left",
        )

        # Calculate daily accrual: TNA * annual_rate / 365
        merged["expected_daily_accrual"] = (
            merged["total_net_assets"] * merged["annual_fee_rate"] / DAYS_IN_YEAR
        ).round(2)

        # Add fund name for readability
        merged["fund_name"] = merged["isin"].map(FUND_UNIVERSE)

        self.results = merged
        logger.info("Calculated accruals for %d records", len(self.results))
        return self.results

    def validate_against_expected(
        self, tolerance: float = 1.0
    ) -> pd.DataFrame:
        """Validate calculated accruals against recorded accruals.

        Args:
            tolerance: Maximum acceptable variance in base currency units.

        Returns:
            DataFrame containing only records that exceed the tolerance.
        """
        if self.results.empty:
            logger.warning("No results to validate. Run calculate_daily_accruals() first.")
            return pd.DataFrame()

        if "recorded_accrual" not in self.results.columns:
            logger.info(
                "No 'recorded_accrual' column in data. Skipping validation."
            )
            return pd.DataFrame()

        logger.info("Validating accruals (tolerance: %.2f)", tolerance)

        self.results["accrual_variance"] = (
            self.results["recorded_accrual"] - self.results["expected_daily_accrual"]
        )
        self.results["variance_pct"] = (
            self.results["accrual_variance"]
            / self.results["expected_daily_accrual"].replace(0, float("nan"))
            * 100.0
        ).round(4)

        exceptions = self.results[
            self.results["accrual_variance"].abs() > tolerance
        ].copy()

        logger.info("Found %d accrual exceptions exceeding tolerance", len(exceptions))
        return exceptions

    def generate_summary(self) -> pd.DataFrame:
        """Generate a summary of management fee accruals by fund and share class.

        Returns:
            Summary DataFrame with totals and averages.
        """
        if self.results.empty:
            return pd.DataFrame()

        summary = (
            self.results.groupby(["fund_name", "isin", "share_class"])
            .agg(
                accrual_days=("expected_daily_accrual", "count"),
                total_accrued=("expected_daily_accrual", "sum"),
                avg_daily_accrual=("expected_daily_accrual", "mean"),
                avg_tna=("total_net_assets", "mean"),
                annual_fee_rate=("annual_fee_rate", "first"),
            )
            .reset_index()
        )

        summary["total_accrued"] = summary["total_accrued"].round(2)
        summary["avg_daily_accrual"] = summary["avg_daily_accrual"].round(2)
        summary["avg_tna"] = summary["avg_tna"].round(2)

        return summary

    def export(self, output_path: str) -> None:
        """Export accrual results to CSV.

        Args:
            output_path: Destination file path.
        """
        if self.results.empty:
            logger.info("No management fee results to export.")
            return

        self.results.to_csv(output_path, index=False)
        logger.info("Management fee accruals exported to: %s", output_path)

        # Also export summary
        summary = self.generate_summary()
        summary_path = Path(output_path).parent / (
            Path(output_path).stem + "_summary.csv"
        )
        summary.to_csv(summary_path, index=False)
        logger.info("Management fee summary exported to: %s", summary_path)


# ---------------------------------------------------------------------------
# Performance Fee Calculator
# ---------------------------------------------------------------------------


class PerformanceFeeCalculator:
    """Calculates performance fees using high-water mark methodology.

    The performance fee is charged on the positive return above the
    high-water mark (HWM). The HWM is the highest NAV per share previously
    achieved at a crystallisation point.

    Attributes:
        nav_data: DataFrame with daily NAV per share.
        fee_schedule: DataFrame with performance fee rates and HWM data.
        results: DataFrame with calculated performance fee accruals.
    """

    def __init__(self):
        """Initialise the performance fee calculator."""
        self.nav_data: pd.DataFrame = pd.DataFrame()
        self.fee_schedule: pd.DataFrame = pd.DataFrame()
        self.results: pd.DataFrame = pd.DataFrame()

    def load_data(self, nav_filepath: str, fee_schedule_filepath: str) -> None:
        """Load NAV and fee schedule data.

        Args:
            nav_filepath: Path to the NAV data CSV.
            fee_schedule_filepath: Path to the fee schedule CSV.

        Raises:
            FileNotFoundError: If either file does not exist.
        """
        for filepath, label in [
            (nav_filepath, "NAV data"),
            (fee_schedule_filepath, "Fee schedule"),
        ]:
            if not Path(filepath).exists():
                raise FileNotFoundError(f"{label} file not found: {filepath}")

        self.nav_data = pd.read_csv(nav_filepath, parse_dates=["nav_date"])
        self.fee_schedule = pd.read_csv(fee_schedule_filepath)

        logger.info(
            "PerformanceFeeCalculator loaded %d NAV records", len(self.nav_data)
        )

    def calculate_performance_fees(self) -> pd.DataFrame:
        """Calculate daily performance fee accruals using high-water mark logic.

        For each fund/share class:
        1. Determine the current high-water mark.
        2. If NAV per share exceeds HWM, calculate the outperformance.
        3. Accrue performance fee = outperformance * shares * perf_fee_rate / 365.
        4. Update the running HWM.

        Returns:
            DataFrame with daily performance fee accrual calculations.
        """
        if self.nav_data.empty or self.fee_schedule.empty:
            logger.warning("Data not loaded.")
            return pd.DataFrame()

        logger.info("Calculating performance fees with high-water mark")

        perf_schedule = self.fee_schedule[
            self.fee_schedule["fee_type"] == "Performance Fee"
        ].copy()

        if perf_schedule.empty:
            logger.info("No performance fee entries in fee schedule.")
            return pd.DataFrame()

        all_results = []

        for _, schedule_row in perf_schedule.iterrows():
            fund_id = schedule_row["fund_id"]
            share_class = schedule_row.get("share_class", "Default")
            perf_fee_rate = schedule_row["annual_fee_rate"]
            initial_hwm = schedule_row.get("high_water_mark", 0.0)

            # Filter NAV data for this fund/share class
            fund_nav = self.nav_data[
                (self.nav_data["fund_id"] == fund_id)
            ].sort_values("nav_date").copy()

            if fund_nav.empty:
                continue

            # Apply high-water mark logic
            running_hwm = initial_hwm
            daily_records = []

            for _, nav_row in fund_nav.iterrows():
                nav_per_share = nav_row["nav_per_share"]
                shares = nav_row.get("shares_outstanding", 0)

                if nav_per_share > running_hwm:
                    outperformance = nav_per_share - running_hwm
                    daily_perf_accrual = round(
                        outperformance * shares * perf_fee_rate / DAYS_IN_YEAR, 2
                    )
                    new_hwm = nav_per_share
                else:
                    outperformance = 0.0
                    daily_perf_accrual = 0.0
                    new_hwm = running_hwm

                daily_records.append(
                    {
                        "fund_id": fund_id,
                        "isin": nav_row.get("isin", ""),
                        "share_class": share_class,
                        "nav_date": nav_row["nav_date"],
                        "nav_per_share": nav_per_share,
                        "high_water_mark": running_hwm,
                        "outperformance": round(outperformance, 6),
                        "shares_outstanding": shares,
                        "perf_fee_rate": perf_fee_rate,
                        "daily_perf_fee_accrual": daily_perf_accrual,
                    }
                )

                running_hwm = new_hwm

            all_results.extend(daily_records)

        self.results = pd.DataFrame(all_results)

        if not self.results.empty:
            self.results["fund_name"] = self.results["isin"].map(FUND_UNIVERSE)

        logger.info(
            "Performance fee calculation complete: %d records", len(self.results)
        )
        return self.results

    def generate_summary(self) -> pd.DataFrame:
        """Generate a summary of performance fee accruals by fund.

        Returns:
            Summary DataFrame.
        """
        if self.results.empty:
            return pd.DataFrame()

        summary = (
            self.results.groupby(["fund_name", "isin", "share_class"])
            .agg(
                total_perf_fee_accrued=("daily_perf_fee_accrual", "sum"),
                days_above_hwm=(
                    "outperformance",
                    lambda x: (x > 0).sum(),
                ),
                max_outperformance=("outperformance", "max"),
                final_hwm=("high_water_mark", "last"),
                final_nav=("nav_per_share", "last"),
            )
            .reset_index()
        )

        summary["total_perf_fee_accrued"] = summary["total_perf_fee_accrued"].round(2)
        return summary

    def export(self, output_path: str) -> None:
        """Export performance fee results to CSV.

        Args:
            output_path: Destination file path.
        """
        if self.results.empty:
            logger.info("No performance fee results to export.")
            return

        self.results.to_csv(output_path, index=False)
        logger.info("Performance fee details exported to: %s", output_path)

        summary = self.generate_summary()
        summary_path = Path(output_path).parent / (
            Path(output_path).stem + "_summary.csv"
        )
        summary.to_csv(summary_path, index=False)
        logger.info("Performance fee summary exported to: %s", summary_path)


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Fee Calculator - Capital Management Co."
    )
    parser.add_argument(
        "--nav-file",
        required=True,
        help="Path to the NAV data CSV file",
    )
    parser.add_argument(
        "--fee-schedule",
        required=True,
        help="Path to the fee schedule CSV file",
    )
    parser.add_argument(
        "--output",
        default="fee_report.csv",
        help="Base path for output files (default: fee_report.csv)",
    )
    parser.add_argument(
        "--type",
        choices=["management", "performance", "all"],
        default="all",
        help="Which fee type to calculate (default: all)",
    )
    return parser.parse_args()


def main() -> None:
    """Main execution flow for fee calculations."""
    args = parse_arguments()

    logger.info("=" * 60)
    logger.info("Fee Calculator - Capital Management Co.")
    logger.info("Run date: %s", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    logger.info("=" * 60)

    output_base = Path(args.output)

    try:
        # Management fees
        if args.type in ("management", "all"):
            logger.info("--- Management Fee Calculation ---")
            mgmt_calc = ManagementFeeCalculator()
            mgmt_calc.load_data(args.nav_file, args.fee_schedule)
            mgmt_calc.calculate_daily_accruals()
            exceptions = mgmt_calc.validate_against_expected()
            if not exceptions.empty:
                logger.warning(
                    "%d management fee exceptions found", len(exceptions)
                )
            mgmt_output = (
                output_base.parent / f"{output_base.stem}_management.csv"
            )
            mgmt_calc.export(str(mgmt_output))

        # Performance fees
        if args.type in ("performance", "all"):
            logger.info("--- Performance Fee Calculation ---")
            perf_calc = PerformanceFeeCalculator()
            perf_calc.load_data(args.nav_file, args.fee_schedule)
            perf_calc.calculate_performance_fees()
            perf_output = (
                output_base.parent / f"{output_base.stem}_performance.csv"
            )
            perf_calc.export(str(perf_output))

            # Display summary
            summary = perf_calc.generate_summary()
            if not summary.empty:
                logger.info("Performance Fee Summary:")
                for _, row in summary.iterrows():
                    logger.info(
                        "  %-40s | Accrued: %12.2f | Days above HWM: %d",
                        row["fund_name"],
                        row["total_perf_fee_accrued"],
                        row["days_above_hwm"],
                    )

    except FileNotFoundError as e:
        logger.error("File error: %s", e)
        sys.exit(1)
    except Exception as e:
        logger.error("Unexpected error: %s", e, exc_info=True)
        sys.exit(1)

    logger.info("Fee calculation complete.")


if __name__ == "__main__":
    main()
