"""
Board Report Data Generator
Capital Management Co. - Fund Governance Simulation

Generates structured data for fund governance board packs, including
performance summaries, risk dashboards, and AUM analysis. Output is
designed to feed into presentation tools or templating engines.

Fund Universe:
    Global Equity Fund              | IE00B4X9L533
    European Bond Fund              | IE00BK5BQ103
    Multi-Asset Growth Fund         | LU0292097234
    Emerging Markets Fund           | IE00BFYN9Y00
    Real Estate Opportunities       | LU0488316133
    Private Credit Fund             | LU0629460675

Usage:
    python report_generator.py --performance perf_data.csv --risk risk_data.csv --aum aum_data.csv --period quarterly --output board_report
"""

import argparse
import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

import pandas as pd
import numpy as np

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

FUND_UNIVERSE = {
    "IE00B4X9L533": "Global Equity Fund",
    "IE00BK5BQ103": "European Bond Fund",
    "LU0292097234": "Multi-Asset Growth Fund",
    "IE00BFYN9Y00": "Emerging Markets Fund",
    "LU0488316133": "Real Estate Opportunities Fund",
    "LU0629460675": "Private Credit Fund",
}

RISK_FREE_RATE = 0.03  # 3% annualised for Sharpe ratio calculation
TRADING_DAYS_PER_YEAR = 252

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
# Report Generator
# ---------------------------------------------------------------------------


class BoardReportGenerator:
    """Generates structured data for fund governance board reports.

    Loads performance, risk, and AUM data from CSV files and produces
    summary tables suitable for quarterly or monthly board packs.

    Attributes:
        performance_data: DataFrame of daily fund performance/returns.
        risk_data: DataFrame of risk metrics (VaR, tracking error, etc.).
        aum_data: DataFrame of daily AUM figures.
        report_period: 'quarterly' or 'monthly'.
        report_date: The reporting date (defaults to today).
    """

    def __init__(
        self,
        report_period: str = "quarterly",
        report_date: Optional[str] = None,
    ):
        """Initialise the report generator.

        Args:
            report_period: 'quarterly' or 'monthly'.
            report_date: Reporting as-of date (YYYY-MM-DD). Defaults to today.
        """
        self.performance_data: pd.DataFrame = pd.DataFrame()
        self.risk_data: pd.DataFrame = pd.DataFrame()
        self.aum_data: pd.DataFrame = pd.DataFrame()
        self.report_period = report_period
        self.report_date = (
            pd.Timestamp(report_date)
            if report_date
            else pd.Timestamp(datetime.now().date())
        )

        logger.info(
            "BoardReportGenerator initialised | Period: %s | As-of: %s",
            self.report_period,
            self.report_date.strftime("%Y-%m-%d"),
        )

    def load_data(
        self,
        performance_file: Optional[str] = None,
        risk_file: Optional[str] = None,
        aum_file: Optional[str] = None,
    ) -> None:
        """Load data from CSV files.

        Args:
            performance_file: Path to performance data CSV.
            risk_file: Path to risk data CSV.
            aum_file: Path to AUM data CSV.

        Raises:
            FileNotFoundError: If a specified file does not exist.
        """
        if performance_file:
            if not Path(performance_file).exists():
                raise FileNotFoundError(
                    f"Performance file not found: {performance_file}"
                )
            self.performance_data = pd.read_csv(
                performance_file, parse_dates=["nav_date"]
            )
            logger.info(
                "Loaded performance data: %d records from %s",
                len(self.performance_data),
                performance_file,
            )

        if risk_file:
            if not Path(risk_file).exists():
                raise FileNotFoundError(f"Risk file not found: {risk_file}")
            self.risk_data = pd.read_csv(risk_file, parse_dates=["as_of_date"])
            logger.info(
                "Loaded risk data: %d records from %s",
                len(self.risk_data),
                risk_file,
            )

        if aum_file:
            if not Path(aum_file).exists():
                raise FileNotFoundError(f"AUM file not found: {aum_file}")
            self.aum_data = pd.read_csv(aum_file, parse_dates=["nav_date"])
            logger.info(
                "Loaded AUM data: %d records from %s",
                len(self.aum_data),
                aum_file,
            )

    # -----------------------------------------------------------------------
    # Performance metrics
    # -----------------------------------------------------------------------

    def calculate_returns(self) -> pd.DataFrame:
        """Calculate period returns for each fund.

        Computes returns over multiple horizons: 1 month, 3 months,
        6 months, YTD, 1 year, and since inception.

        Returns:
            DataFrame with return metrics per fund.
        """
        if self.performance_data.empty:
            logger.warning("No performance data loaded.")
            return pd.DataFrame()

        logger.info("Calculating fund returns")

        results = []
        horizons = {
            "1M": 21,
            "3M": 63,
            "6M": 126,
            "1Y": 252,
        }

        for isin, group in self.performance_data.groupby("isin"):
            group = group.sort_values("nav_date")
            fund_name = FUND_UNIVERSE.get(isin, isin)
            latest_nav = group["nav_per_share"].iloc[-1]
            latest_date = group["nav_date"].iloc[-1]

            record = {
                "fund_name": fund_name,
                "isin": isin,
                "report_date": latest_date,
                "latest_nav": round(latest_nav, 4),
            }

            # Period returns
            for label, days in horizons.items():
                if len(group) >= days:
                    start_nav = group["nav_per_share"].iloc[-days]
                    period_return = (latest_nav / start_nav - 1) * 100.0
                    record[f"return_{label}"] = round(period_return, 2)
                else:
                    record[f"return_{label}"] = None

            # YTD return
            ytd_data = group[
                group["nav_date"] >= pd.Timestamp(latest_date.year, 1, 1)
            ]
            if len(ytd_data) > 1:
                ytd_start = ytd_data["nav_per_share"].iloc[0]
                record["return_YTD"] = round(
                    (latest_nav / ytd_start - 1) * 100.0, 2
                )
            else:
                record["return_YTD"] = None

            # Since inception
            inception_nav = group["nav_per_share"].iloc[0]
            record["return_since_inception"] = round(
                (latest_nav / inception_nav - 1) * 100.0, 2
            )

            results.append(record)

        return pd.DataFrame(results)

    def calculate_volatility(self) -> pd.DataFrame:
        """Calculate annualised volatility for each fund.

        Uses daily log returns to compute standard deviation, then
        annualises by multiplying by sqrt(252).

        Returns:
            DataFrame with volatility metrics per fund.
        """
        if self.performance_data.empty:
            logger.warning("No performance data loaded.")
            return pd.DataFrame()

        logger.info("Calculating annualised volatility")

        results = []

        for isin, group in self.performance_data.groupby("isin"):
            group = group.sort_values("nav_date")
            fund_name = FUND_UNIVERSE.get(isin, isin)

            # Daily log returns
            log_returns = np.log(
                group["nav_per_share"] / group["nav_per_share"].shift(1)
            ).dropna()

            if len(log_returns) < 20:
                continue

            daily_vol = log_returns.std()
            annual_vol = daily_vol * np.sqrt(TRADING_DAYS_PER_YEAR)

            # Rolling 30-day volatility (latest)
            rolling_vol = (
                log_returns.rolling(window=30).std().iloc[-1]
                * np.sqrt(TRADING_DAYS_PER_YEAR)
            )

            results.append(
                {
                    "fund_name": fund_name,
                    "isin": isin,
                    "daily_volatility": round(daily_vol * 100, 4),
                    "annualised_volatility": round(annual_vol * 100, 2),
                    "rolling_30d_volatility": round(rolling_vol * 100, 2),
                    "observation_days": len(log_returns),
                }
            )

        return pd.DataFrame(results)

    def calculate_sharpe_ratio(self) -> pd.DataFrame:
        """Calculate the Sharpe ratio for each fund.

        Sharpe = (annualised return - risk-free rate) / annualised volatility

        Returns:
            DataFrame with Sharpe ratios per fund.
        """
        if self.performance_data.empty:
            return pd.DataFrame()

        logger.info("Calculating Sharpe ratios (Rf = %.2f%%)", RISK_FREE_RATE * 100)

        results = []

        for isin, group in self.performance_data.groupby("isin"):
            group = group.sort_values("nav_date")
            fund_name = FUND_UNIVERSE.get(isin, isin)

            log_returns = np.log(
                group["nav_per_share"] / group["nav_per_share"].shift(1)
            ).dropna()

            if len(log_returns) < TRADING_DAYS_PER_YEAR:
                continue

            # Use the trailing 1-year data
            recent_returns = log_returns.iloc[-TRADING_DAYS_PER_YEAR:]
            annual_return = recent_returns.mean() * TRADING_DAYS_PER_YEAR
            annual_vol = recent_returns.std() * np.sqrt(TRADING_DAYS_PER_YEAR)

            sharpe = (
                (annual_return - RISK_FREE_RATE) / annual_vol
                if annual_vol > 0
                else None
            )

            results.append(
                {
                    "fund_name": fund_name,
                    "isin": isin,
                    "annualised_return": round(annual_return * 100, 2),
                    "annualised_volatility": round(annual_vol * 100, 2),
                    "risk_free_rate": RISK_FREE_RATE * 100,
                    "sharpe_ratio": round(sharpe, 2) if sharpe is not None else None,
                }
            )

        return pd.DataFrame(results)

    # -----------------------------------------------------------------------
    # Performance summary table
    # -----------------------------------------------------------------------

    def generate_performance_summary(self) -> pd.DataFrame:
        """Generate a consolidated performance summary table for the board.

        Combines returns, volatility, and Sharpe ratio into a single table.

        Returns:
            Consolidated performance summary DataFrame.
        """
        logger.info("Generating fund performance summary table")

        returns_df = self.calculate_returns()
        vol_df = self.calculate_volatility()
        sharpe_df = self.calculate_sharpe_ratio()

        if returns_df.empty:
            return pd.DataFrame()

        summary = returns_df.copy()

        if not vol_df.empty:
            summary = summary.merge(
                vol_df[["isin", "annualised_volatility", "rolling_30d_volatility"]],
                on="isin",
                how="left",
            )

        if not sharpe_df.empty:
            summary = summary.merge(
                sharpe_df[["isin", "sharpe_ratio"]],
                on="isin",
                how="left",
            )

        return summary

    # -----------------------------------------------------------------------
    # Risk dashboard
    # -----------------------------------------------------------------------

    def generate_risk_dashboard(self) -> pd.DataFrame:
        """Generate a risk dashboard summary for the board pack.

        If risk_data is loaded, it summarises VaR, tracking error, and
        other risk measures. Otherwise, it computes basic risk metrics
        from performance data.

        Returns:
            Risk dashboard DataFrame.
        """
        logger.info("Generating risk dashboard summary")

        if not self.risk_data.empty:
            # Use pre-calculated risk data
            latest_risk = self.risk_data.sort_values("as_of_date").groupby(
                "isin"
            ).last().reset_index()
            latest_risk["fund_name"] = latest_risk["isin"].map(FUND_UNIVERSE)
            return latest_risk

        # Fall back to computing basic risk metrics from performance data
        if self.performance_data.empty:
            return pd.DataFrame()

        results = []
        for isin, group in self.performance_data.groupby("isin"):
            group = group.sort_values("nav_date")
            fund_name = FUND_UNIVERSE.get(isin, isin)

            daily_returns = (
                group["nav_per_share"].pct_change().dropna()
            )

            if len(daily_returns) < 30:
                continue

            # Value at Risk (95% historical)
            var_95 = daily_returns.quantile(0.05)

            # Maximum drawdown
            cumulative = (1 + daily_returns).cumprod()
            running_max = cumulative.cummax()
            drawdown = (cumulative - running_max) / running_max
            max_drawdown = drawdown.min()

            # Skewness and kurtosis
            skew = daily_returns.skew()
            kurt = daily_returns.kurtosis()

            results.append(
                {
                    "fund_name": fund_name,
                    "isin": isin,
                    "var_95_daily": round(var_95 * 100, 4),
                    "max_drawdown_pct": round(max_drawdown * 100, 2),
                    "skewness": round(skew, 4),
                    "kurtosis": round(kurt, 4),
                    "positive_days_pct": round(
                        (daily_returns > 0).mean() * 100, 1
                    ),
                    "observation_days": len(daily_returns),
                }
            )

        return pd.DataFrame(results)

    # -----------------------------------------------------------------------
    # AUM summary
    # -----------------------------------------------------------------------

    def generate_aum_summary(self) -> pd.DataFrame:
        """Generate an AUM summary for the reporting period.

        Returns:
            AUM summary DataFrame with period start, end, and change.
        """
        if self.aum_data.empty:
            logger.info("No AUM data loaded.")
            return pd.DataFrame()

        logger.info("Generating AUM summary")

        results = []
        for isin, group in self.aum_data.groupby("isin"):
            group = group.sort_values("nav_date")
            fund_name = FUND_UNIVERSE.get(isin, isin)

            period_start_aum = group["total_net_assets"].iloc[0]
            period_end_aum = group["total_net_assets"].iloc[-1]
            avg_aum = group["total_net_assets"].mean()

            results.append(
                {
                    "fund_name": fund_name,
                    "isin": isin,
                    "period_start_date": group["nav_date"].iloc[0],
                    "period_end_date": group["nav_date"].iloc[-1],
                    "period_start_aum": round(period_start_aum, 2),
                    "period_end_aum": round(period_end_aum, 2),
                    "aum_change": round(period_end_aum - period_start_aum, 2),
                    "aum_change_pct": round(
                        (period_end_aum / period_start_aum - 1) * 100, 2
                    )
                    if period_start_aum != 0
                    else None,
                    "avg_aum": round(avg_aum, 2),
                    "min_aum": round(group["total_net_assets"].min(), 2),
                    "max_aum": round(group["total_net_assets"].max(), 2),
                }
            )

        return pd.DataFrame(results)

    # -----------------------------------------------------------------------
    # Export
    # -----------------------------------------------------------------------

    def export_all(self, output_dir: str) -> None:
        """Export all report sections to CSV files.

        Args:
            output_dir: Directory to write output files into.
        """
        out = Path(output_dir)
        out.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d")
        period_label = self.report_period

        # Performance summary
        perf_summary = self.generate_performance_summary()
        if not perf_summary.empty:
            path = out / f"performance_summary_{period_label}_{timestamp}.csv"
            perf_summary.to_csv(path, index=False)
            logger.info("Performance summary exported to: %s", path)

        # Risk dashboard
        risk_dashboard = self.generate_risk_dashboard()
        if not risk_dashboard.empty:
            path = out / f"risk_dashboard_{period_label}_{timestamp}.csv"
            risk_dashboard.to_csv(path, index=False)
            logger.info("Risk dashboard exported to: %s", path)

        # AUM summary
        aum_summary = self.generate_aum_summary()
        if not aum_summary.empty:
            path = out / f"aum_summary_{period_label}_{timestamp}.csv"
            aum_summary.to_csv(path, index=False)
            logger.info("AUM summary exported to: %s", path)

        logger.info("All report data exported to: %s", out)


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Board Report Generator - Capital Management Co."
    )
    parser.add_argument(
        "--performance",
        help="Path to performance data CSV",
    )
    parser.add_argument(
        "--risk",
        help="Path to risk data CSV",
    )
    parser.add_argument(
        "--aum",
        help="Path to AUM data CSV",
    )
    parser.add_argument(
        "--period",
        choices=["quarterly", "monthly"],
        default="quarterly",
        help="Report period type (default: quarterly)",
    )
    parser.add_argument(
        "--report-date",
        help="Report as-of date in YYYY-MM-DD format (default: today)",
    )
    parser.add_argument(
        "--output",
        default="board_report",
        help="Output directory for report files (default: board_report)",
    )
    return parser.parse_args()


def main() -> None:
    """Main execution flow for board report generation."""
    args = parse_arguments()

    logger.info("=" * 60)
    logger.info("Board Report Generator - Capital Management Co.")
    logger.info("Run date: %s", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    logger.info("=" * 60)

    generator = BoardReportGenerator(
        report_period=args.period,
        report_date=args.report_date,
    )

    try:
        generator.load_data(
            performance_file=args.performance,
            risk_file=args.risk,
            aum_file=args.aum,
        )

        generator.export_all(args.output)

    except FileNotFoundError as e:
        logger.error("File error: %s", e)
        sys.exit(1)
    except Exception as e:
        logger.error("Unexpected error: %s", e, exc_info=True)
        sys.exit(1)

    logger.info("Board report generation complete.")


if __name__ == "__main__":
    main()
