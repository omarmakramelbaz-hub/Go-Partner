import 'package:flutter/material.dart';

class HelpBoxWidget extends StatefulWidget {
  const HelpBoxWidget({super.key, required this.answer, required this.question});
  final String answer;
  final String question;

  @override
  State<HelpBoxWidget> createState() => _HelpBoxWidgetState();
}

class _HelpBoxWidgetState extends State<HelpBoxWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => setState(() => isExpanded = !isExpanded),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 190),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpanded ? const Color(0xffFFD6B5) : const Color(0xffECEEF1),
              ),
              boxShadow: [
                BoxShadow(
                  color: navy.withOpacity(isExpanded ? .07 : .04),
                  blurRadius: isExpanded ? 18 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF0E3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.help_outline_rounded, color: orange, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          widget.question,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 14.5,
                            height: 1.35,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isExpanded ? orange : const Color(0xffF3F5F7),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        isExpanded ? Icons.remove_rounded : Icons.add_rounded,
                        color: isExpanded ? Colors.white : softText,
                        size: 21,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 190),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(46, 12, 4, 2),
                    child: Text(
                      widget.answer,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        color: softText,
                        fontSize: 13,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
