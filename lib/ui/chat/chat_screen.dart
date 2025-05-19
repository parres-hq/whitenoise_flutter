import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input.dart';
import 'package:whitenoise/ui/chat/widgets/contact_info.dart';
import 'package:whitenoise/ui/chat/widgets/message_widget.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_default_data.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_hero_dialog_route.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reactions_dialog_widget.dart';
import 'package:whitenoise/ui/chat/widgets/status_message_item_widget.dart';
import '../../routing/routes.dart';
import '../core/themes/assets.dart';
import '../core/themes/colors.dart';
import '../../domain/dummy_data/dummy_messages.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  void showEmojiBottomSheet({
    required MessageModel message,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 310,
          child: EmojiPicker(
            onEmojiSelected: ((category, emoji) {
              // pop the bottom sheet
              Navigator.pop(context);
              addReactionToMessage(
                message: message,
                reaction: emoji.emoji,
              );
            }),
          ),
        );
      },
    );
  }

  // add reaction to message
  void addReactionToMessage({
    required MessageModel message,
    required String reaction,
  }) {
    message.reactions.add(reaction);
    // update UI
    setState(() {});
  }

  void sendNewMessage(MessageModel newMessage){
    setState(() {
      messages.insert(0,newMessage);
    });
  }


  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.colorE2E2E2,),
          onPressed: () {},
        ),
        title: const ContactInfo(title: "Marek", imgPath: AssetsPaths.icImage,),
        actions: [
          GestureDetector(
            onTap:() => context.go(Routes.newChat),
            child: Container(margin: EdgeInsets.only(right: 15), child: Icon(CarbonIcons.search, color: AppColors.colorE2E2E2,) ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Column(
            children: [
              Expanded(
                child: // list view builder for example messages
                ListView.builder(
                  reverse: true,
                  itemCount: messages.length+1,
                  itemBuilder: (BuildContext context, int index) {
                    //get chatting user info
                    if(index == messages.length){
                      return Container(
                        padding: EdgeInsets.only(left: 30, right: 30),
                        child: Column(
                          children: [
                            Gap(80),
                            CircleAvatar(
                              backgroundImage: AssetImage(AssetsPaths.icImage),
                              radius: 40,
                            ),
                            Gap(10),
                            Text('Marek', style: TextStyle(color: AppColors.color202320, fontSize: 23),),
                            Gap(10),
                            Text('marek@crupek.com', style: TextStyle(color: AppColors.grey2,),),
                            Gap(10),
                            Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(
                                text: 'efaeg ', // Default style
                                style: TextStyle(color: AppColors.grey2,),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'eaeed ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.grey2),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'eaeed ',
                                    style: TextStyle(color: AppColors.grey2),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.grey2),
                                  ),
                                  TextSpan(
                                    text: 'eaeed ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.grey2),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'eaeed ',
                                    style: TextStyle(color: AppColors.grey2),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'kka',
                                    style: TextStyle(color: AppColors.grey2),
                                  ),
                                ],
                              ),
                            ),
                            Gap(20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CarbonIcons.email, color: AppColors.color727772, size: 14,),
                                Gap(5),
                                Text.rich(
                                  textAlign: TextAlign.center,
                                  TextSpan(
                                    text: 'Chat invite sent to ', // Default style
                                    style: TextStyle(color: AppColors.color727772,),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: "Marek",
                                        style: TextStyle(color: AppColors.color202320),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Gap(10),
                            StatusMessageItemWidget(icon:  CarbonIcons.checkmark,highlightedContent:  "Marek", content: " accepted the invite"),
                            Gap(30),
                          ],
                        ),
                      );
                    }else{
                      // get message
                      final message = messages[index];
                      return GestureDetector(
                        // wrap your message widget with a [GestureDectector] or [InkWell]
                        onLongPress: () {
                          // navigate with a custom [HeroDialogRoute] to [ReactionsDialogWidget]
                          Navigator.of(context).push(
                            HeroDialogRoute(
                              builder: (context) {
                                return ReactionsDialogWidget(
                                  id: message.id, // unique id for message
                                  menuItems: message.isMe?DefaultData.myMessageMenuItems:DefaultData.menuItems,
                                  messageWidget: MessageWidget(
                                      message: message, isGroupMessage: false, messageIndex: index,), // message widget
                                  onReactionTap: (reaction) {
                                    if (reaction == '⋯') {//'➕'
                                      // show emoji picker container
                                      showEmojiBottomSheet(
                                        message: message,
                                      );
                                    } else {
                                      // add reaction to message
                                      addReactionToMessage(
                                        message: message,
                                        reaction: reaction,
                                      );
                                    }
                                  },
                                  onContextMenuTap: (menuItem) {
                                    print('menu item: $menuItem');
                                    // handle context menu item
                                  },
                                  // align widget to the right for my message and to the left for contact message
                                  // default is [Alignment.centerRight]
                                  widgetAlignment: message.isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                );
                              },
                            ),
                          );
                        },
                        // wrap message with [Hero] widget
                        child: Hero(
                          tag: message.id,
                          child: MessageWidget(message: message, isGroupMessage: false,messageIndex: index,),
                        ),
                      );
                    }
                  },
                ),
              ),
              // bottom chat input
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: ChatInput(padding: const EdgeInsets.all(0), onSend: sendNewMessage) // BottomChatField(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
