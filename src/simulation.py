
import random

from .beta_binomial import BetaBinomialModel


# Reproducible simulation
random.seed(42)

# Synthetic equipment conditions
EQUIPMENT_PROFILES = {
    "Reliable": 0.02,
    "Moderate": 0.10,
    "Poor": 0.25
}

TOTAL_OBSERVATIONS = 20


def simulate_qc(true_failure_probability, total_observations):
    failures = sum(
        random.random() < true_failure_probability
        for _ in range(total_observations)
    )

    return failures


def run_simulation():

    model = BetaBinomialModel()

    print("\nBETA-BINOMIAL EQUIPMENT RELIABILITY SIMULATION")
    print("=" * 72)

    print(
        f"{'Equipment':<12}"
        f"{'True Fail':<12}"
        f"{'Failures':<12}"
        f"{'Posterior Mean':<18}"
        f"{'95% CI':<22}"
    )

    print("-" * 72)

    for equipment, true_probability in EQUIPMENT_PROFILES.items():

        failures = simulate_qc(
            true_probability,
            TOTAL_OBSERVATIONS
        )

        result = model.fit(
            failures=failures,
            total_observations=TOTAL_OBSERVATIONS
        )

        lower = result["failure_probability_ci_lower"]
        upper = result["failure_probability_ci_upper"]

        print(
            f"{equipment:<12}"
            f"{true_probability:<12.3f}"
            f"{failures:<12}"
            f"{result['mean_failure_probability']:<18.4f}"
            f"[{lower:.4f}, {upper:.4f}]"
        )


if __name__ == "__main__":
    run_simulation()
