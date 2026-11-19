DateTime? _homeStartDate;
DateTime? _homeEndDate;

DateTime? get homeStartDate => _homeStartDate;
DateTime? get homeEndDate => _homeEndDate;

void setHomeRentalDates({
  required DateTime? startDate,
  required DateTime? endDate,
}) {
  _homeStartDate = startDate;
  _homeEndDate = endDate;
  notifyListeners();
}

void notifyListeners() {}