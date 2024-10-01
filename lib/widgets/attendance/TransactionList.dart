import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const TransactionList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true, //This is important
      physics: const NeverScrollableScrollPhysics(), //This is important
      itemCount: transactions.length,
      itemBuilder: (BuildContext context, int index) {
        if (transactions[index].isNotEmpty) {
          return _transactionItem(transactions[index], context);
        }
        return null;
      },
    );
  }

  Widget _transactionItem(Map<String, dynamic> transaction, context) {
    print(transaction);
    List<String> data;
    if (transaction['status'] == "") {
      return Container();
    }
    if (transaction['tracking2'] != null) {
      data = List<String>.from(
          transaction['tracking2'].map((item) => item.toString()));
    } else {
      // Handle the situation when 'tracking2' is null
      data = [];
    }

    List<CategoryTime> categoryTimeList = data.map((item) {
      var splitItem = item.split(' - ');
      return CategoryTime(splitItem[0], splitItem[1]);
    }).toList();

    String formattedDate = transaction['date'] != null
        ? transaction['date'].toLocal().toString().substring(0, 10)
        : 'N/A';

    return (transaction['status'] == "Absent" ||
            transaction['status'] == "On Leave")
        ? Card(
            child: Column(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  color: Theme.of(context).primaryColorLight,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: cell("Status", transaction['status'], null),
                )
              ],
            ),
          )
        : Card(
            child: Column(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(
                height: 10,
              ),
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: cell("Name", transaction['name'], null)),
                    const VerticalDivider(
                      width: 1,
                    ),
                    cell("Date", formattedDate, null)
                  ],
                ),
              ),
              const Divider(),
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: cell("Company", transaction['company'], null)),
                    const VerticalDivider(
                      width: 1,
                    ),
                    cell("Status", transaction['status'], null)
                  ],
                ),
              ),
              const Divider(),
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    cell(
                        "Day's Start",
                        (transaction['in_time'] == "")
                            ? "-"
                            : DateFormat('hh:mm a').format(
                                DateFormat("HH:mm:ss")
                                    .parse(transaction['in_time'])),
                        Icons.wb_sunny_sharp,
                        CrossAxisAlignment.center),
                    const VerticalDivider(
                      width: 1,
                    ),
                    cell(
                        "Day's End",
                        (transaction['out_time'] == "")
                            ? "-"
                            : DateFormat('hh:mm a').format(
                                DateFormat("HH:mm:ss")
                                    .parse(transaction['out_time'])),
                        Icons.wb_twilight_sharp,
                        CrossAxisAlignment.center),
                    /*if (transaction['ot_status'] != "") ...[
                      const VerticalDivider(
                        width: 1,
                      ),
                      cell(
                          "OT IN",
                          (transaction['ot_in_datetime'] == "")
                              ? "-"
                              : DateFormat('hh:mm a').format(
                                  DateFormat("HH:mm:ss")
                                      .parse(transaction['ot_in_datetime'])),
                          CrossAxisAlignment.center),
                      const VerticalDivider(
                        width: 1,
                      ),
                      cell(
                          "OT OUT",
                          (transaction['ot_out_datetime'] == "")
                              ? "-"
                              : DateFormat('hh:mm a').format(
                                  DateFormat("HH:mm:ss")
                                      .parse(transaction['ot_out_datetime'])),
                          CrossAxisAlignment.center),
                    ],*/
                  ],
                ),
              ),
              const Divider(),
              if (categoryTimeList.isNotEmpty)
                Wrap(
                  spacing: 8.0, // space between two adjacent chips
                  runSpacing: 4.0, // space between two lines of chips
                  children:
                      categoryTimeList.map<Widget>((CategoryTime timeObj) {
                    DateTime trackingTime =
                        DateFormat("HH:mm:ss").parse(timeObj.time);
                    String formattedTime =
                        DateFormat('hh:mm a').format(trackingTime);
                    return Chip(
                      label: Column(
                        children: [
                          Text(timeObj.category),
                          Text(formattedTime),
                        ],
                      ),
                    );
                  }).toList(),
                )
            ],
          ));
  }
}

Widget cell(String title, String value, IconData? icon,
    [CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start]) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Row(
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(icon),
          ),
        Column(crossAxisAlignment: crossAxisAlignment, children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value)
        ]),
      ],
    ),
  );
}

class CategoryTime {
  final String category;
  final String time;

  CategoryTime(this.category, this.time);
}
