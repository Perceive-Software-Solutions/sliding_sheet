import 'dart:math';

// ignore: avoid_classes_with_only_static_members
///Holds a list of constants used within the application
class Functions {
  ///Only displays a value over its final percentage. 
  ///The final split is outputted in values
  static double animateOver(double value, {double percent = 1.0}){
    assert(percent != null && percent >= 0 && percent <= 1.0);
    assert(value != null && value >= 0);

    double remainder = 1.0 - percent;

    return max(0, (value - percent) / remainder);
  }

  ///Only displays a value over its final percentage. 
  ///The final split is outputted in values
  static double animateOverFirst(double value, {double percent = 1.0}){
    assert(percent != null && percent >= 0 && percent <= 1.0);
    assert(value != null && value >= 0 && value <= 1.0);

    return min(1.0, value / percent);
  }

  //Only displays a value within a range
  static double animateRange(double value, {double start = 0.0, double end = 1.0}){
    assert(start != null && start >= 0 && start <= 1.0);
    assert(end != null && end >= 0 && end <= 1.0);
    assert(value != null && value >= 0 && value <= 1.0);

    //The ratio of the animate over first 
    //that will be the percintile for the animate over
    double ratioOfFirst = start/end;

    return animateOver(
      animateOverFirst(value, percent: end), 
      percent: ratioOfFirst 
    );
  }

}