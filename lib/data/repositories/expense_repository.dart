import 'package:expensetracker/data/models/datetime/date_time_helper.dart';
import 'package:expensetracker/data/models/expence_item.dart';

class ExpenseRepository {
  // list of ALL expenses
List<ExpenceItem> overallExpenseList = [];
// get expense list
List<ExpenceItem> getExpenseList() {
  return overallExpenseList;
}

// add new expense
void addExpense(ExpenceItem item) {
  overallExpenseList.add(item);
}
// delete expense
void deleteExpense(int id) {
  overallExpenseList.removeWhere((item) => item.id == id);
}
// get weekday (mon, tues, etc) from a dateTime
String getDayName(DateTime dateTime) {
  switch (dateTime.weekday) {
    case 1:
    return 'Monday';
    case 2:
    return 'Tuesday';
    case 3:
    return 'Wednesday';
    case 4:
    return 'Thursday';
    case 5:
    return 'Friday';
    case 6:
    return 'Saturday';
    case 7:
    return 'Sunday';
    default:
    return '';
    }
}
// get the date for the start of the week ( wee)
DateTime getStartOfWeek() {
  DateTime? startOfWeek ;
  DateTime today = DateTime.now();
 for (int i = 0; i < 7; i++) {
    DateTime date =  today.subtract(Duration(days: i));
    if (date.weekday == DateTime.monday) {
      startOfWeek = date;
      break;
    }
  }
  return startOfWeek!;
}

/*
e.g.

overallExpenseList =

[ food, 2023/01/30, $10 ],
[ hat, 2023/01/30, $15 ],
[ drinks, 2023/01/31, $1 ],
[ food, 2023/02/01, $5 ],
[ food, 2023/02/01, $6 ],
[ food, 2023/02/03, $7 ],
[ food, 2023/02/05, $10 ],
[ food, 2023/02/05, $11 ],

->

DailyExpenseSummary =

[ 2023/01/30: $25 ],
[ 2023/01/31: $1 ],
[ 2023/02/01: $11 ],
[ 2023/02/03: $7 ],
[.2023/02/05:$21.],

*/
Map<String, double> getDailyExpenseSummary() {
  Map<String, double> dailyExpenseSummary = {};
  for (var item in overallExpenseList) {
    String dateString = convertDateTimeToString(item.date);
    if (dailyExpenseSummary.containsKey(dateString)) {
      dailyExpenseSummary[dateString] = dailyExpenseSummary[dateString]! + item.amount;
    } else {
      dailyExpenseSummary[dateString] = item.amount;
    }
  }
  return dailyExpenseSummary;
}
}