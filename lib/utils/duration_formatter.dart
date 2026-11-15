/// Formats video duration into a readable format (mm:ss or hh:mm:ss).
class DurationFormatter {
  static String format(int totalSeconds) {
    if (totalSeconds <= 0) {
      return "00:00";
    }

    final Duration duration = Duration(seconds: totalSeconds);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    final String twoDigitMinutes = minutes.toString().padLeft(2, '0');
    final String twoDigitSeconds = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final String twoDigitHours = hours.toString().padLeft(2, '0');
      return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }
}
