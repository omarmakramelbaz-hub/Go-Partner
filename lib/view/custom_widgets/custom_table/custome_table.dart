import 'package:flutter/material.dart';

class CustomAppTable extends StatefulWidget {
  const CustomAppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onDeleteRow,
  });

  final List<String> columns;
  final List<DataRow> rows;
  final void Function(int)? onDeleteRow;

  @override
  State<CustomAppTable> createState() => _CustomAppTableState();
}

class _CustomAppTableState extends State<CustomAppTable> {
  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);

    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          horizontalMargin: 14,
          columnSpacing: 24,
          headingRowHeight: 52,
          dataRowMinHeight: 50,
          dataRowMaxHeight: 62,
          headingRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
            return states.contains(WidgetState.hovered)
                ? const Color(0xffFFF0E3)
                : const Color(0xffF6F7F9);
          }),
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
            return states.contains(WidgetState.hovered) ? const Color(0xffFFFDFC) : Colors.white;
          }),
          border: TableBorder.all(
            color: const Color(0xffECEEF1),
            width: 1,
            borderRadius: BorderRadius.circular(17),
          ),
          dividerThickness: .7,
          headingTextStyle: const TextStyle(
            color: navy,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
          dataTextStyle: const TextStyle(
            color: softText,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          columns: List.generate(
            widget.columns.length,
            (index) => DataColumn(label: Center(child: Text(widget.columns[index]))),
          ),
          rows: List.generate(widget.rows.length, (index) => DataRow(cells: widget.rows[index].cells)),
        ),
      ),
    );
  }
}
