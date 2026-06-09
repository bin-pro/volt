// Weight conversion utilities
const double _lbToKg = 0.45359237;

double lbToKg(double lb) => lb * _lbToKg;
double kgToLb(double kg) => kg / _lbToKg;

/// Store always as kg; convert for display
double toKg(double value, String unit) => unit == 'lb' ? lbToKg(value) : value;
double fromKg(double kg, String unit) => unit == 'lb' ? kgToLb(kg) : kg;

String formatWeight(double kg, String displayUnit) {
  final val = fromKg(kg, displayUnit);
  if (val == val.truncateToDouble()) {
    return '${val.toInt()}';
  }
  return val.toStringAsFixed(1);
}

/// Snap rest seconds to nearest preset: 60/90/120/150/180
int snapRestSeconds(int seconds) {
  const presets = [60, 90, 120, 150, 180];
  return presets.reduce((a, b) =>
      (a - seconds).abs() < (b - seconds).abs() ? a : b);
}

/// Epley 1RM formula: 1RM = weight * (1 + reps/30)
double calculate1RM(double weightKg, int reps) {
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30);
}
