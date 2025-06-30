import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';

class DeveloperScreen extends ConsumerStatefulWidget {
  const DeveloperScreen({super.key});

  @override
  ConsumerState<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends ConsumerState<DeveloperScreen> {
  final _logger = Logger('DeveloperScreen');
  final _messageController = TextEditingController(text: 'Test message from developer screen');

  String? _lastSentMessage;
  List<MessageWithTokensData>? _lastFetchedMessages;
  String? _error;
  bool _isLoading = false;
  GroupData? _selectedGroup;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }

  Future<void> _loadGroups() async {
    await ref.read(groupsProvider.notifier).loadGroups();
  }

  Future<void> _testSendMessage() async {
    if (_selectedGroup == null) {
      _setError('Please select a group first');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccount == null) {
        throw Exception('No active account found');
      }

      final pubkey = await publicKeyFromString(publicKeyString: activeAccount.pubkey);
      final groupId = await groupIdFromString(hexString: _selectedGroup!.mlsGroupId);

      _logger.info('Sending message to group: ${_selectedGroup!.name}');

      final result = await sendMessageToGroup(
        pubkey: pubkey,
        groupId: groupId,
        message: _messageController.text,
        kind: 1, // Text message kind
      );

      setState(() {
        _lastSentMessage = '''
Sent Message:
ID: ${result.id}
Pubkey: ${result.pubkey}
Kind: ${result.kind}
Created At: ${result.createdAt}
Content: ${result.content}
Tokens (${result.tokens.length} total):
${result.tokens.asMap().entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}
        ''';
        _isLoading = false;
      });

      _logger.info('Message sent successfully: ${result.id}');
    } catch (e, st) {
      _logger.severe('Error sending message', e, st);
      _setError('Error sending message: $e');
    }
  }

  Future<void> _testFetchMessages() async {
    if (_selectedGroup == null) {
      _setError('Please select a group first');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccount == null) {
        throw Exception('No active account found');
      }

      final pubkey = await publicKeyFromString(publicKeyString: activeAccount.pubkey);
      final groupId = await groupIdFromString(hexString: _selectedGroup!.mlsGroupId);

      _logger.info('Fetching messages for group: ${_selectedGroup!.name}');

      final messages = await fetchMessagesForGroup(
        pubkey: pubkey,
        groupId: groupId,
      );

      setState(() {
        _lastFetchedMessages = messages;
        _isLoading = false;
      });

      _logger.info('Fetched ${messages.length} messages');

      // Log tokens for each message
      for (int i = 0; i < messages.length; i++) {
        final message = messages[i];
        _logger.info('Message ${i + 1} tokens (${message.tokens.length} total):');
        for (int j = 0; j < message.tokens.length; j++) {
          _logger.info('  Token $j: ${message.tokens[j]}');
        }
      }
    } catch (e, st) {
      _logger.severe('Error fetching messages', e, st);
      _setError('Error fetching messages: $e');
    }
  }

  void _setError(String error) {
    setState(() {
      _error = error;
      _isLoading = false;
    });
  }

  Widget _buildGroupSelector() {
    final groupsState = ref.watch(groupsProvider);
    final groups = groupsState.groups ?? [];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Group for Testing',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Gap(12.h),
            if (groups.isEmpty)
              Text(
                'No groups found. Create a group first.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
              )
            else
              DropdownButtonFormField<GroupData>(
                value: _selectedGroup,
                decoration: InputDecoration(
                  labelText: 'Group',
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                items:
                    groups.map((group) {
                      return DropdownMenuItem<GroupData>(
                        value: group,
                        child: Text(
                          group.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (GroupData? value) {
                  setState(() {
                    _selectedGroup = value;
                    _lastSentMessage = null;
                    _lastFetchedMessages = null;
                    _error = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Message Content',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Gap(12.h),
            TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: const TextStyle(color: Colors.white),
                hintText: 'Enter test message...',
                hintStyle: const TextStyle(color: Colors.white60),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Actions',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Gap(12.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedGroup != null && !_isLoading ? _testSendMessage : null,
                    icon: Icon(CarbonIcons.send, size: 16.sp),
                    label: const Text('Send Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: context.colors.primaryForeground,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedGroup != null && !_isLoading ? _testFetchMessages : null,
                    icon: Icon(CarbonIcons.download, size: 16.sp),
                    label: const Text('Fetch Messages'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.secondary,
                      foregroundColor: context.colors.secondaryForeground,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading) ...[
              Gap(12.h),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) {
      return Card(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        color: context.colors.destructive.withValues(alpha: 0.1),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CarbonIcons.warning, color: context.colors.destructive, size: 16.sp),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.destructive,
                      ),
                    ),
                  ),
                ],
              ),
              Gap(8.h),
              Text(
                _error!,
                style: TextStyle(
                  color: context.colors.destructive,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_lastSentMessage != null) {
      return Card(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        color: context.colors.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CarbonIcons.checkmark, color: context.colors.primary, size: 16.sp),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      'Message Sent Successfully',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Gap(8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: context.colors.border),
                ),
                child: Text(
                  _lastSentMessage!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.sp,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_lastFetchedMessages != null) {
      return Card(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        color: context.colors.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CarbonIcons.checkmark, color: context.colors.primary, size: 16.sp),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      '${_lastFetchedMessages!.length} messages fetched',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Gap(8.h),
              Container(
                width: double.infinity,
                height: 300.h,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: context.colors.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _lastFetchedMessages!.isEmpty
                        ? 'No messages found in this group.'
                        : _lastFetchedMessages!
                            .asMap()
                            .entries
                            .map((entry) {
                              final index = entry.key;
                              final message = entry.value;
                              return '''
Message ${index + 1}:
  ID: ${message.id}
  Pubkey: ${message.pubkey}
  Kind: ${message.kind}
  Created At: ${message.createdAt}
  Content: ${message.content}
  Tokens (${message.tokens.length} total):
${message.tokens.asMap().entries.map((e) => '    ${e.key}: ${e.value}').join('\n')}
''';
                            })
                            .join('\n---\n'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.sp,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral,
      appBar: const CustomAppBar(title: Text('Developer Testing')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bridge Methods Testing',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Gap(8.h),
            Text(
              'Test send_message_to_group and fetch_messages_for_group bridge methods. The token data format will be displayed in the results.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            Gap(16.h),
            _buildGroupSelector(),
            _buildMessageInput(),
            _buildActionButtons(),
            _buildResults(),
          ],
        ),
      ),
    );
  }
}
