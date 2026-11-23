import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../../../app/locale_controller.dart';
import '../models/chat_message_ui_model.dart';
import '../view_models/community_chat_view_model.dart';
import '../widgets/chat_message_bubble.dart';

class CommunityChatPage extends StatefulWidget {
  const CommunityChatPage({super.key, required this.viewModel});
  final CommunityChatViewModel viewModel;
  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  String? _lastMessageId;
  double? _viewportHeight;
  bool _unread = false;

  @override
  void initState() {
    super.initState();
    final messages = widget.viewModel.messages;
    _lastMessageId = messages.isEmpty ? null : messages.last.id;
    widget.viewModel.addListener(_onMessagesChanged);
    _scroll.addListener(_onScroll);
    _scrollToLatest();
  }

  @override
  void didUpdateWidget(covariant CommunityChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onMessagesChanged);
      widget.viewModel.addListener(_onMessagesChanged);
      final messages = widget.viewModel.messages;
      _lastMessageId = messages.isEmpty ? null : messages.last.id;
      _input.clear();
      _scrollToLatest();
    }
  }

  void _onScroll() {
    if (_unread && _scroll.hasClients && _scroll.position.extentAfter < 20) {
      setState(() => _unread = false);
    }
  }

  void _onMessagesChanged() {
    final messages = widget.viewModel.messages;
    final latest = messages.isEmpty ? null : messages.last;
    if (latest?.id == _lastMessageId) return;
    final follow =
        !_scroll.hasClients ||
        _scroll.position.extentAfter < 100 ||
        latest?.senderId == widget.viewModel.currentStudentId;
    _lastMessageId = latest?.id;
    if (follow) {
      _scrollToLatest(animate: true);
    } else {
      setState(() => _unread = true);
    }
  }

  void _scrollToLatest({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scroll.hasClients) return;
      if (_unread) setState(() => _unread = false);
      if (animate) {
        await _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
      // Lazy layout can refine the extent after the newest bubble appears.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients && _scroll.position.extentAfter > 1) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onMessagesChanged);
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _guidelines() {
    final s = CampusStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('guidelines')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final key in [
                'ruleRespect',
                'rulePrivacy',
                'ruleIncidents',
                'ruleEmergency',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('• ${s.t(key)}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.t('close')),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty || widget.viewModel.sending) return;
    final success = await widget.viewModel.send(text);
    if (!mounted) return;
    if (success) {
      _input.clear();
      _focus.requestFocus();
      _scrollToLatest(animate: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(CampusStrings.of(context).t('messageFailed'))),
      );
    }
  }

  Future<void> _block(ChatMessageUiModel message) async {
    final s = CampusStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('blockSender')),
        content: Text(s.t('blockBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.t('blockSender')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    var key = 'blockUnavailable';
    if (widget.viewModel.blockSender case final block?) {
      try {
        await block(message.senderId);
        key = 'blocked';
      } catch (_) {
        key = 'tryAgain';
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.t(key))));
    }
  }

  Future<void> _report(ChatMessageUiModel message) async {
    final s = CampusStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('reportMessageTitle')),
        content: Text(s.t('reportMessageBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.t('reportMessage')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    var key = 'reportUnavailable';
    if (widget.viewModel.reportMessage case final callback?) {
      try {
        await callback(message);
        key = 'reportReceived';
      } catch (_) {
        key = 'tryAgain';
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(CampusStrings.of(context).t(key))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = CampusStrings.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final vm = widget.viewModel;
            final messages = vm.messages;
            return LayoutBuilder(
              builder: (context, constraints) {
                if (_viewportHeight != constraints.maxHeight) {
                  final follow =
                      !_scroll.hasClients || _scroll.position.extentAfter < 100;
                  _viewportHeight = constraints.maxHeight;
                  if (follow) _scrollToLatest();
                }
                final compact = constraints.maxHeight < 500;
                final minimumHeight =
                    300 *
                    MediaQuery.textScalerOf(context)
                        .scale(1)
                        .clamp(1, 2)
                        .toDouble();
                final content = Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!compact)
                                  Text(
                                    s.t('community'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  s.t('chatTitle'),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _guidelines,
                            tooltip: s.t('guidelines'),
                            icon: const Icon(Icons.policy_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: vm.loading
                          ? StudentStatePanel(
                              icon: Icons.forum_outlined,
                              title: s.t('loadingMessages'),
                              message: '',
                              loading: true,
                            )
                          : vm.hasError
                          ? SingleChildScrollView(
                              child: StudentStatePanel(
                                icon: Icons.cloud_off,
                                title: s.t('loadError'),
                                message: s.t('tryAgain'),
                                action: s.t('retry'),
                                onAction: vm.loadMessages == null
                                    ? null
                                    : vm.refresh,
                              ),
                            )
                          : messages.isEmpty
                          ? SingleChildScrollView(
                              child: StudentStatePanel(
                                icon: Icons.forum_outlined,
                                title: s.t('noMessages'),
                                message: s.t('noMessagesBody'),
                              ),
                            )
                          : ListView.builder(
                              key: const ValueKey('chat-message-list'),
                              controller: _scroll,
                              reverse: false,
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final local = message.sentAt.toLocal();
                                final previous = index == 0
                                    ? null
                                    : messages[index - 1];
                                final previousDate = previous?.sentAt.toLocal();
                                final newDay =
                                    previousDate == null ||
                                    DateUtils.dateOnly(previousDate) !=
                                        DateUtils.dateOnly(local);
                                final grouped =
                                    !newDay &&
                                    previous?.senderId == message.senderId &&
                                    previous?.role == message.role &&
                                    message.sentAt
                                            .difference(previous!.sentAt)
                                            .inMinutes <
                                        5;
                                final today = DateUtils.dateOnly(
                                  DateTime.now(),
                                );
                                final day = DateUtils.dateOnly(local);
                                final label = day == today
                                    ? s.t('today')
                                    : day ==
                                          today.subtract(
                                            const Duration(days: 1),
                                          )
                                    ? s.t('yesterday')
                                    : s.date(local, time: false);
                                return Column(
                                  key: ValueKey(message.id),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (newDay)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: Text(
                                            label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium,
                                          ),
                                        ),
                                      ),
                                    ChatMessageBubble(
                                      grouped: grouped,
                                      message: message,
                                      isMine:
                                          message.senderId ==
                                          vm.currentStudentId,
                                      onReport: () => _report(message),
                                      onBlock: () => _block(message),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                    if (_unread)
                      TextButton.icon(
                        key: const ValueKey('new-messages'),
                        onPressed: () => _scrollToLatest(animate: true),
                        icon: const Icon(Icons.arrow_downward),
                        label: Text(s.t('newMessages')),
                      ),
                    if (vm.sending)
                      Semantics(liveRegion: true, child: Text(s.t('sending'))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey('chat-input'),
                              controller: _input,
                              focusNode: _focus,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              onTapAlwaysCalled: true,
                              onTap: () {
                                _focus.requestFocus();
                                // Reopen the IME even after Android Back hid it
                                // while this field retained focus.
                                SystemChannels.textInput.invokeMethod<void>(
                                  'TextInput.show',
                                );
                              },
                              enabled:
                                  !vm.sending && !vm.loading && !vm.hasError,
                              minLines: 1,
                              maxLines: compact ? 2 : 4,
                              maxLength: 1000,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: s.t('messageHint'),
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _input,
                            builder: (context, value, _) => IconButton.filled(
                              key: const ValueKey('send-message'),
                              onPressed:
                                  vm.sending ||
                                      vm.loading ||
                                      vm.hasError ||
                                      value.text.trim().isEmpty
                                  ? null
                                  : _send,
                              tooltip: s.t('send'),
                              icon: vm.sending
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                // On a short landscape screen or with the keyboard visible,
                // keep the composer reachable without clipping enlarged text.
                if (constraints.maxHeight < minimumHeight) {
                  return SingleChildScrollView(
                    reverse: true,
                    child: SizedBox(height: minimumHeight, child: content),
                  );
                }
                return content;
              },
            );
          },
        ),
      ),
    );
  }
}
