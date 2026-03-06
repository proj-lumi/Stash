/// First day of month at 00:00:00
DateTime startOfMonth(int year, int month) => DateTime(year, month, 1);

/// Last day of month at 23:59:59.999
DateTime endOfMonth(int year, int month) =>
    DateTime(year, month + 1, 0, 23, 59, 59, 999);

bool isSameMonth(DateTime a, int year, int month) =>
    a.year == year && a.month == month;
