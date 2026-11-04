
from src.bayesian_diagnostic import BayesianDiagnosticModel


model = BayesianDiagnosticModel(
    prevalence=0.10,
    sensitivity=0.90,
    specificity=0.95
)

positive_result = model.calculate("Positive")
negative_result = model.calculate("Negative")

print("\nBAYESIAN DIAGNOSTIC ASSESSMENT")
print("=" * 60)

print(
    "Posterior probability after positive test:",
    f"{positive_result['posterior_probability']:.2%}"
)

print(
    "Posterior probability after negative test:",
    f"{negative_result['posterior_probability']:.2%}"
)
