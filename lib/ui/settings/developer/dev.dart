import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
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
  List<ChatMessageData>? _lastFetchedMessages;
  List<MessageWithTokensData>? _lastRawMessages;
  String? _comparisonResult;
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
    _logger.info('=== Developer Screen Initialized ===');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.info('Post-frame callback triggered, loading groups...');
      _loadGroups();
    });
  }

  Future<void> _loadGroups() async {
    _logger.info('=== Loading groups ===');
    try {
      await ref.read(groupsProvider.notifier).loadGroups();
      final groupsState = ref.read(groupsProvider);
      final groups = groupsState.groups ?? [];
      _logger.info('Groups loaded successfully. Count: ${groups.length}');

      if (groups.isEmpty) {
        _logger.warning('No groups found. User needs to create a group first.');
      } else {
        _logger.info('Available groups:');
        for (int i = 0; i < groups.length; i++) {
          final group = groups[i];
          _logger.info('  ${i + 1}. ${group.name} (MLS ID: ${group.mlsGroupId})');
        }
      }
    } catch (e, st) {
      _logger.severe('Error loading groups: $e', e, st);
    }
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
      _logger.info('=== Starting send message test ===');
      _logger.info('Selected group: ${_selectedGroup!.name}');
      _logger.info('Group MLS ID: ${_selectedGroup!.mlsGroupId}');
      _logger.info('Message to send: "${_messageController.text}"');

      final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccount == null) {
        throw Exception('No active account found');
      }

      _logger.info('Active account pubkey: ${activeAccount.pubkey}');

      final pubkey = await publicKeyFromString(publicKeyString: activeAccount.pubkey);
      _logger.info('Converted pubkey object: ${pubkey.toString()}');

      final groupId = await groupIdFromString(hexString: _selectedGroup!.mlsGroupId);
      _logger.info('Converted groupId object: ${groupId.toString()}');

      _logger.info('Calling sendMessageToGroup...');

      final result = await sendMessageToGroup(
        pubkey: pubkey,
        groupId: groupId,
        message: _messageController.text,
        kind: 1, // Text message kind
      );

      _logger.info('=== Send message completed successfully ===');
      _logger.info('Message sent with ID: ${result.id}');
      _logger.info('Result details:');
      _logger.info('  ID: ${result.id}');
      _logger.info('  Pubkey: ${result.pubkey}');
      _logger.info('  Kind: ${result.kind}');
      _logger.info('  Created At: ${result.createdAt}');
      _logger.info('  Content: "${result.content}"');
      _logger.info('  Tokens count: ${result.tokens.length}');

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

      _logger.info('Message successfully sent and UI updated');
    } catch (e, st) {
      _logger.severe('=== Error in send message ===');
      _logger.severe('Error type: ${e.runtimeType}');
      _logger.severe('Error message: $e');
      _logger.severe('Stack trace: $st');
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
      _logger.info('=== Starting fetch messages test ===');
      _logger.info('Selected group: ${_selectedGroup!.name}');
      _logger.info('Group MLS ID: ${_selectedGroup!.mlsGroupId}');

      final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccount == null) {
        throw Exception('No active account found');
      }

      _logger.info('Active account pubkey: ${activeAccount.pubkey}');

      final pubkey = await publicKeyFromString(publicKeyString: activeAccount.pubkey);
      _logger.info('Converted pubkey object: ${pubkey.toString()}');

      final groupId = await groupIdFromString(hexString: _selectedGroup!.mlsGroupId);
      _logger.info('Converted groupId object: ${groupId.toString()}');

      _logger.info('Calling fetchAggregatedMessagesForGroup...');

      final messages = await fetchAggregatedMessagesForGroup(
        pubkey: pubkey,
        groupId: groupId,
      );

      _logger.info('Raw API response - message count: ${messages.length}');
      _logger.info('Raw messages: ${messages.toString()}');

      setState(() {
        _lastFetchedMessages = messages;
        _isLoading = false;
      });

      _logger.info('=== Fetch completed successfully ===');
      _logger.info('Total messages fetched: ${messages.length}');

      // Log detailed message information
      if (messages.isEmpty) {
        _logger.warning('No messages found in group ${_selectedGroup!.name}');
        _logger.info('This could mean:');
        _logger.info('1. No messages have been sent to this group yet');
        _logger.info('2. Messages were sent but not yet synced');
        _logger.info('3. There is an issue with the group ID or pubkey');
      } else {
        _logger.info('=== Message Details ===');
        for (int i = 0; i < messages.length; i++) {
          final message = messages[i];
          _logger.info('Message ${i + 1}:');
          _logger.info('  ID: ${message.id}');
          _logger.info('  Pubkey: ${message.pubkey}');
          _logger.info('  Kind: ${message.kind}');
          _logger.info('  Created At: ${message.createdAt}');
          _logger.info('  Content: "${message.content}"');
          _logger.info('  Is Deleted: ${message.isDeleted}');
        }
      }
    } catch (e, st) {
      _logger.severe('=== Error in fetch messages ===');
      _logger.severe('Error type: ${e.runtimeType}');
      _logger.severe('Error message: $e');
      _logger.severe('Stack trace: $st');
      _setError('Error fetching messages: $e');
    }
  }

  Future<void> _testBothFetchMethods() async {
    if (_selectedGroup == null) {
      _setError('Please select a group first');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _comparisonResult = null;
    });

    try {
      _logger.info('=== Starting both fetch methods test ===');
      _logger.info('Selected group: ${_selectedGroup!.name}');
      _logger.info('Group MLS ID: ${_selectedGroup!.mlsGroupId}');

      // Step 1: Get active account
      _logger.info('Step 1: Getting active account...');
      final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccount == null) {
        throw Exception('No active account found');
      }
      _logger.info('Active account pubkey: ${activeAccount.pubkey}');

      // Step 2: Convert pubkey (with retry for disposal issues)
      _logger.info('Step 2: Converting pubkey...');
      PublicKey pubkey;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          _logger.info('Pubkey conversion attempt $attempt...');
          pubkey = await publicKeyFromString(publicKeyString: activeAccount.pubkey);
          _logger.info('Pubkey converted successfully on attempt $attempt');
          break;
        } catch (e) {
          _logger.warning('Pubkey conversion attempt $attempt failed: $e');
          if (attempt == 3) {
            _logger.severe('Failed to convert pubkey after 3 attempts: $e');
            throw Exception('Failed to convert pubkey after 3 attempts: $e');
          }
          // Wait a bit before retry
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Step 3: Convert group ID (with retry for disposal issues)
      _logger.info('Step 3: Converting group ID...');
      GroupId groupId;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          _logger.info('Group ID conversion attempt $attempt...');
          groupId = await groupIdFromString(hexString: _selectedGroup!.mlsGroupId);
          _logger.info('Group ID converted successfully on attempt $attempt');
          break;
        } catch (e) {
          _logger.warning('Group ID conversion attempt $attempt failed: $e');
          if (attempt == 3) {
            _logger.severe('Failed to convert group ID after 3 attempts: $e');
            throw Exception('Failed to convert group ID after 3 attempts: $e');
          }
          // Wait a bit before retry
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Step 4: Fetch raw messages (with retry for disposal issues)
      _logger.info('Step 4: Fetching raw messages...');
      List<MessageWithTokensData> rawMessages = [];
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          _logger.info('Raw messages fetch attempt $attempt...');

          // Create fresh objects for each attempt to avoid disposal issues
          final freshPubkey = await publicKeyFromString(publicKeyString: activeAccount.pubkey);
          final freshGroupId = await groupIdFromString(hexString: _selectedGroup!.mlsGroupId);

          rawMessages = await fetchMessagesForGroup(
            pubkey: freshPubkey,
            groupId: freshGroupId,
          );
          _logger.info('Raw messages fetched successfully on attempt $attempt. Count: ${rawMessages.length}');
          break;
        } catch (e, st) {
          _logger.warning('Raw messages fetch attempt $attempt failed: $e');
          if (e.toString().contains('DroppableDisposedException')) {
            _logger.warning('Detected disposal exception, will retry with fresh objects');
          }
          if (attempt == 3) {
            _logger.severe('Failed to fetch raw messages after 3 attempts: $e');
            _logger.severe('Stack trace: $st');
            throw Exception('Failed to fetch raw messages after 3 attempts: $e');
          }
          // Wait a bit before retry
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      // Step 5: Fetch aggregated messages (with retry for disposal issues)
      _logger.info('Step 5: Fetching aggregated messages...');
      List<ChatMessageData> aggregatedMessages = [];
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          _logger.info('Aggregated messages fetch attempt $attempt...');

          // Create fresh objects for each attempt to avoid disposal issues
          final freshPubkey = await publicKeyFromString(publicKeyString: activeAccount.pubkey);
          final freshGroupId = await groupIdFromString(hexString: _selectedGroup!.mlsGroupId);

          aggregatedMessages = await fetchAggregatedMessagesForGroup(
            pubkey: freshPubkey,
            groupId: freshGroupId,
          );
          _logger.info('Aggregated messages fetched successfully on attempt $attempt. Count: ${aggregatedMessages.length}');
          break;
        } catch (e, st) {
          _logger.warning('Aggregated messages fetch attempt $attempt failed: $e');
          if (e.toString().contains('DroppableDisposedException')) {
            _logger.warning('Detected disposal exception, will retry with fresh objects');
          }
          if (attempt == 3) {
            _logger.severe('Failed to fetch aggregated messages after 3 attempts: $e');
            _logger.severe('Stack trace: $st');
            throw Exception('Failed to fetch aggregated messages after 3 attempts: $e');
          }
          // Wait a bit before retry
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      // Step 6: Process and log results
      _logger.info('Step 6: Processing results...');

      // Detailed logging for raw messages
      if (rawMessages.isNotEmpty) {
        _logger.info('=== Raw Messages Details ===');
        for (int i = 0; i < rawMessages.length; i++) {
          final message = rawMessages[i];
          _logger.info('Raw Message ${i + 1}:');
          _logger.info('  ID: ${message.id}');
          _logger.info('  Pubkey: ${message.pubkey}');
          _logger.info('  Kind: ${message.kind}');
          _logger.info('  Created At: ${message.createdAt}');
          _logger.info('  Content: "${message.content}"');
          _logger.info('  Tokens count: ${message.tokens.length}');
          if (message.tokens.isNotEmpty) {
            _logger.info('  First few tokens: ${message.tokens.take(3).join(', ')}');
          }
        }
      } else {
        _logger.warning('No raw messages found');
      }

      // Detailed logging for aggregated messages
      if (aggregatedMessages.isNotEmpty) {
        _logger.info('=== Aggregated Messages Details ===');
        for (int i = 0; i < aggregatedMessages.length; i++) {
          final message = aggregatedMessages[i];
          _logger.info('Aggregated Message ${i + 1}:');
          _logger.info('  ID: ${message.id}');
          _logger.info('  Pubkey: ${message.pubkey}');
          _logger.info('  Kind: ${message.kind}');
          _logger.info('  Created At: ${message.createdAt}');
          _logger.info('  Content: "${message.content}"');
          _logger.info('  Is Deleted: ${message.isDeleted}');
        }
      } else {
        _logger.warning('No aggregated messages found');
      }

      // Generate comparison result
      final comparison = '''
=== FETCH METHODS COMPARISON ===

RAW MESSAGES (${rawMessages.length} total):
${rawMessages.isEmpty ? 'No raw messages found' : rawMessages.asMap().entries.map((e) => '''
${e.key + 1}. ID: ${e.value.id}
   Content: "${e.value.content}"
   Tokens: ${e.value.tokens.length}
   Created: ${DateTime.fromMillisecondsSinceEpoch(e.value.createdAt.toInt() * 1000)}''').join('\n\n')}

AGGREGATED MESSAGES (${aggregatedMessages.length} total):
${aggregatedMessages.isEmpty ? 'No aggregated messages found' : aggregatedMessages.asMap().entries.map((e) => '''
${e.key + 1}. ID: ${e.value.id}
   Content: "${e.value.content}"
   Deleted: ${e.value.isDeleted ? "YES" : "NO"}
   Created: ${DateTime.fromMillisecondsSinceEpoch(e.value.createdAt.toInt() * 1000)}''').join('\n\n')}

ANALYSIS:
- Raw vs Aggregated count: ${rawMessages.length} vs ${aggregatedMessages.length}
- Difference: ${rawMessages.length - aggregatedMessages.length} messages
${rawMessages.isEmpty && aggregatedMessages.isEmpty ? '- Both methods returned empty results' : ''}
${rawMessages.isNotEmpty && aggregatedMessages.isEmpty ? '- Raw has data but aggregated is empty (aggregation issue?)' : ''}
${rawMessages.isEmpty && aggregatedMessages.isNotEmpty ? '- Aggregated has data but raw is empty (unusual!)' : ''}
${rawMessages.length == aggregatedMessages.length && rawMessages.isNotEmpty ? '- Both methods returned same count (good sign!)' : ''}
      ''';

      setState(() {
        _lastRawMessages = rawMessages;
        _lastFetchedMessages = aggregatedMessages;
        _comparisonResult = comparison;
        _isLoading = false;
      });

      _logger.info('=== Both fetch methods completed successfully ===');
      _logger.info('Raw: ${rawMessages.length}, Aggregated: ${aggregatedMessages.length}');

    } catch (e, st) {
      _logger.severe('=== Error in both fetch methods test ===');
      _logger.severe('Error type: ${e.runtimeType}');
      _logger.severe('Error message: $e');
      _logger.severe('Full error details: ${e.toString()}');
      _logger.severe('Stack trace: $st');

      // Try to provide more specific error context
      String errorContext = 'Unknown error occurred';
      if (e.toString().contains('DroppableDisposedException')) {
        errorContext = 'Rust object disposal error - try restarting the app or recreating the group';
      } else if (e.toString().contains('pubkey')) {
        errorContext = 'Error with public key conversion or format';
      } else if (e.toString().contains('group')) {
        errorContext = 'Error with group ID or group access';
      } else if (e.toString().contains('fetch')) {
        errorContext = 'Error calling fetch API methods';
      } else if (e.toString().contains('account')) {
        errorContext = 'Error with account data or authentication';
      }

      _setError('$errorContext: $e');
    }
  }

  Future<void> _testSimpleFetch() async {
    if (_selectedGroup == null) {
      _setError('Please select a group first');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _comparisonResult = null;
    });

    try {
      _logger.info('=== Starting simple fetch test ===');
      _logger.info('Selected group: ${_selectedGroup!.name}');
      _logger.info('Group MLS ID: ${_selectedGroup!.mlsGroupId}');

      final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccount == null) {
        throw Exception('No active account found');
      }
      _logger.info('Active account pubkey: ${activeAccount.pubkey}');

      _logger.info('Creating pubkey and groupId objects...');
      final pubkey = await publicKeyFromString(publicKeyString: activeAccount.pubkey);
      final groupId = await groupIdFromString(hexString: _selectedGroup!.mlsGroupId);
      _logger.info('Objects created successfully');

      _logger.info('Calling fetchAggregatedMessagesForGroup immediately...');
      final messages = await fetchAggregatedMessagesForGroup(
        pubkey: pubkey,
        groupId: groupId,
      );

      _logger.info('Simple fetch completed successfully!');
      _logger.info('Message count: ${messages.length}');

      setState(() {
        _lastFetchedMessages = messages;
        _comparisonResult = '''
=== SIMPLE FETCH TEST RESULT ===

SUCCESS! Fetched ${messages.length} aggregated messages.

${messages.isEmpty ? 'No messages found in this group.' : messages.asMap().entries.map((e) => '''
Message ${e.key + 1}:
  ID: ${e.value.id}
  Content: "${e.value.content}"
  Created: ${DateTime.fromMillisecondsSinceEpoch(e.value.createdAt.toInt() * 1000)}
  Deleted: ${e.value.isDeleted ? "YES" : "NO"}''').join('\n\n')}

This simple test worked! The disposal issue might be related to:
- Multiple object creation in the retry logic
- Timing between object creation and usage
- Complex interaction between different fetch methods
        ''';
        _isLoading = false;
      });

    } catch (e, st) {
      _logger.severe('=== Simple fetch test failed ===');
      _logger.severe('Error: $e');
      _logger.severe('Stack trace: $st');

      if (e.toString().contains('DroppableDisposedException')) {
        _setError('Simple fetch also failed with disposal error. This suggests a fundamental issue with Rust object lifecycle. Try restarting the app completely.');
      } else {
        _setError('Simple fetch failed: $e');
      }
    }
  }

  void _setError(String error) {
    setState(() {
      _error = error;
      _isLoading = false;
      _comparisonResult = null;
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
                  _logger.info('=== Group selection changed ===');
                  if (value != null) {
                    _logger.info('Selected group: ${value.name}');
                    _logger.info('Group MLS ID: ${value.mlsGroupId}');
                  } else {
                    _logger.info('No group selected (null)');
                  }

                  setState(() {
                    _selectedGroup = value;
                    _lastSentMessage = null;
                    _lastFetchedMessages = null;
                    _lastRawMessages = null;
                    _comparisonResult = null;
                    _error = null;
                  });

                  _logger.info('UI state cleared and updated');
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
            // First row of buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedGroup != null && !_isLoading ? _testSendMessage : null,
                    icon: Icon(CarbonIcons.send, size: 16.sp),
                    label: const Text('Send Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
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
                    label: const Text('Fetch Aggregated'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Gap(12.h),
            // Second row of buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedGroup != null && !_isLoading ? _testBothFetchMethods : null,
                    icon: Icon(CarbonIcons.compare, size: 16.sp),
                    label: const Text('Compare Both'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
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
                    onPressed: _selectedGroup != null && !_isLoading ? _testSimpleFetch : null,
                    icon: Icon(CarbonIcons.debug, size: 16.sp),
                    label: const Text('Simple Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
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
        color: Colors.red.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CarbonIcons.warning, color: Colors.red, size: 16.sp),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              Gap(8.h),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.red,
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
        color: Colors.green.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CarbonIcons.checkmark, color: Colors.green, size: 16.sp),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      'Message Sent Successfully',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
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
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
        color: Colors.green.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CarbonIcons.checkmark, color: Colors.green, size: 16.sp),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      '${_lastFetchedMessages!.length} messages fetched',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
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
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
  Created At: ${DateTime.fromMillisecondsSinceEpoch(message.createdAt.toInt() * 1000).toLocal()}
  Content: ${message.content}
  Deleted: ${message.isDeleted ? "YES" : "NO"}
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

    if (_comparisonResult != null) {
      return Card(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        color: Colors.green.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CarbonIcons.compare, color: Colors.green, size: 16.sp),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      'Comparison Results',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
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
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Text(
                  _comparisonResult!,
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

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
              'Test send_message_to_group and fetch_aggregated_messages_for_group bridge methods. Aggregated messages provide processed chat data without token details.',
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
