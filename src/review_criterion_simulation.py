
import random

from scipy.stats import beta

from .beta_binomial import BetaBinomialModel


random.seed(42)

EQUIPMENT_PROFILES = {
    "Reliable": 0.02,
    "Moderate": 0.10,
    "Poor": 0.25
}

SAMPLE_SIZES = [20, 50, 100, 500]
REPETITIONS = 1000

FAILURE_LIMIT = 0.10
POSTERIOR_CONFIDENCE = 0.90


def simulate_failures(true_probability, sample_size):

    return sum(
        random.random() < true_probability
        for _ in range(sample_size)
    )


def evaluate_review_rule(true_probability, sample_size):

    model = BetaBinomialModel()

    review_count = 0

    for _ in range(REPETITIONS):

        failures = simulate_failures(
            true_probability,
            sample_size
        )

        result = model.fit(
            failures=failures,
            total_observations=sample_size
        )

        posterior_probability = 1 - beta.cdf(
            FAILURE_LIMIT,
            result["posterior_alpha"],
            result["posterior_beta"]
        )

        if posterior_probability >= POSTERIOR_CONFIDENCE:
            review_count += 1

    return review_count / REPETITIONS


def run_simulation():

    print("\nBAYESIAN EQUIPMENT REVIEW CRITERION")
    print("=" * 85)

    print(
        f"Review rule: P(failure rate > {FAILURE_LIMIT:.0%} | QC data)"
        f" >= {POSTERIOR_CONFIDENCE:.0%}"
    )

    for equipment, true_probability in EQUIPMENT_PROFILES.items():

        print(f"\nEquipment: {equipment}")
        print(f"True failure probability: {true_probability:.0%}")
        print("-" * 65)

        print(f"{'Sample Size':<15}{'Review Rate':<20}")

        for sample_size in SAMPLE_SIZES:

            review_rate = evaluate_review_rule(
                true_probability,
                sample_size
            )

            print(
                f"{sample_size:<15}"
                f"{review_rate:.2%}"
            )


if __name__ == "__main__":
    run_simulation()
