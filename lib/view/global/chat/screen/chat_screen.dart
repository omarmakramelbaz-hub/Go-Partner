import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_loading/custom_loading.dart';
import '../../../custom_widgets/no_data_widget/no_data_widget.dart';
import '../../../layout/auth/controller/auth_controller.dart';
import '../../widget/messages_widget.dart';
import '../controller/chat_controller.dart';
import '../model/chat_model.dart';

class ChatScreenArgs {
  final String orderId;
  final String receiverDeviceToken;
  final String senderDeviceToken;
  final String senderName;
  final String receiverName;
  final String vendorDeviceToken;
  final bool isVendor;
  final String accountType;
  ChatScreenArgs({
    required this.receiverDeviceToken,
    required this.senderDeviceToken,
    required this.senderName,
    required this.receiverName,
    required this.orderId,
    required this.vendorDeviceToken,
    required this.isVendor,
    required this.accountType,
    int? delegateId,
  });
}

class ChatScreen extends StatefulWidget {
  final ChatScreenArgs args;
  static const routeName = 'ChatScreen';

  const ChatScreen({super.key, required this.args});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageEC = TextEditingController();
  @override
  void initState() {
    Future.microtask(() {
      context.read<ChatController>().initial(widget.args.orderId);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, chatController, _) {
        return Scaffold(
          appBar: CustomAppBar(context, title: Text(tr(AppLocaleKey.messages))),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: chatController.chatStream,
                  builder: (context, snapshot) {
                    log(snapshot.connectionState.name);
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                        return const Center(child: CustomLoading());
                      case ConnectionState.waiting:
                        return const Center(child: CustomLoading());
                      case ConnectionState.active:
                        if (snapshot.hasData) {
                          List<ChatMessageModel> messages = snapshot.data!.docs
                              .map((e) => ChatMessageModel.fromJson(e.data()))
                              .toList();

                          return GroupedListView<ChatMessageModel, DateTime>(
                            elements: messages,
                            groupBy: (element) => DateTime(
                              element.messageTime!.year,
                              element.messageTime!.month,
                              element.messageTime!.day,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            itemComparator: (item1, item2) => item1.messageTime!.compareTo(item2.messageTime!),
                            groupItemBuilder: (context, element, groupStart, groupEnd) {
                              return MessageWidget(message: element);
                            },
                            groupSeparatorBuilder: (date) =>
                                Center(child: Text(DateMethods.formatToDate(date.toIso8601String()))),
                            separator: const SizedBox(height: 15),
                            reverse: true,
                            order: GroupedListOrder.DESC,
                          );
                        } else {
                          return const NoDataWidget();
                        }
                      case ConnectionState.done:
                        return const CustomLoading();
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(child: CustomFormField(controller: _messageEC)),
                    IconButton(
                      onPressed: () {
                        final txt = _messageEC.text;
                        if (_messageEC.text != '') {
                          chatController.send(
                            txt,
                            context.read<AuthController>().profile!.id!,
                            widget.args.receiverDeviceToken,
                            widget.args.senderDeviceToken,
                            widget.args.senderName,
                            widget.args.receiverName,
                            widget.args.vendorDeviceToken,
                            widget.args.isVendor,
                            widget.args.accountType,
                          );
                        }
                        _messageEC.clear();
                      },
                      icon: Icon(Icons.send_rounded, color: AppColor.mainAppColor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
