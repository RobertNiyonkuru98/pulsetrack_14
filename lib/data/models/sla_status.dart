/// The four SLA states a task can be in.
/// These are the words the assignment asks for, so keep them exact.
enum SlaStatus { onTrack, atRisk, overdue, completed }

extension SlaStatusLabel on SlaStatus {
  String get label {
    switch (this) {
      case SlaStatus.onTrack:
        return 'On Track';
      case SlaStatus.atRisk:
        return 'At Risk';
      case SlaStatus.overdue:
        return 'Overdue';
      case SlaStatus.completed:
        return 'Completed';
    }
  }
}
