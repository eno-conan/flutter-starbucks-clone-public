import 'package:flutter/material.dart';
import '../../../../../constants/my_colors.dart';
import '../../../../../shared/widgets/texts/my_custom_text.dart';

/// Custom selector widget for temperature and size selection
class CustomSelector extends StatelessWidget {
  const CustomSelector({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> items;
  final int selectedIndex;
  final void Function(int) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: items.length * 80,
      child: SegmentedButton<int>(
        style: ButtonStyle(
          side: MaterialStateProperty.all(BorderSide(color: MyColors.greenButton)),
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return MyColors.greenButton;
            }
            return Colors.transparent;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return MyColors.greenButton;
          }),
          textStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.w500)),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 8)),
        ),
        segments: List.generate(
          items.length,
          (index) => ButtonSegment<int>(
            value: index,
            label: Text(items[index], textAlign: TextAlign.center),
          ),
        ),
        selected: {selectedIndex},
        onSelectionChanged: (Set<int> selection) {
          if (selection.isNotEmpty) {
            onSelected(selection.first);
          }
        },
        showSelectedIcon: false,
      ),
    );
  }
}

/// Count selector widget for order quantity
class CountSelector extends StatelessWidget {
  const CountSelector({
    super.key,
    required this.count,
    required this.minusCount,
    required this.plusCount,
  });

  final int count;
  final VoidCallback minusCount;
  final VoidCallback plusCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: .start,
          children: [
            const MyCustomText(text: '数量', fontSize: 14, textColor: MyColors.greyText),
            MyCustomText(text: count.toString(), fontSize: 14, textColor: Colors.black),
          ],
        ),
        const Spacer(),
        IconButton(onPressed: minusCount, icon: Icon(Icons.do_disturb_on_outlined), iconSize: 28),
        IconButton(onPressed: plusCount, icon: const Icon(Icons.add_circle_outline), iconSize: 28),
      ],
    );
  }
}

/// Padding wrapper widget for consistent content padding
class PaddingContents extends StatelessWidget {
  const PaddingContents({super.key, required this.body});
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: body);
  }
}
