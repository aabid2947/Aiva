import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/mail_service.dart';

class MailScreen extends StatefulWidget {
  const MailScreen({super.key, MailService? service}) : _service = service;

  final MailService? _service;

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  late final MailService _service = widget._service ?? MailService();
  final _criteriaController = TextEditingController();

  MailStatus? _status;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _criteriaController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await _service.status();
      _criteriaController.text = status.importanceCriteria ?? '';
      if (mounted) setState(() => _status = status);
    } on DioException catch (e) {
      if (mounted) setState(() => _error = _messageFrom(e));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _connect() async {
    try {
      final url = await _service.connectUrl();
      final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!launched) {
        _snack("Couldn't open the browser.");
      } else {
        _snack('Finish in your browser, then tap Refresh.');
      }
    } on DioException catch (e) {
      if (mounted) _snack(_messageFrom(e));
    }
  }

  Future<void> _save() async {
    final status = _status;
    if (status == null) return;
    setState(() => _saving = true);
    try {
      final updated = await _service.updateWatch(
        enabled: status.enabled,
        importanceCriteria: _criteriaController.text.trim().isEmpty
            ? null
            : _criteriaController.text.trim(),
      );
      if (mounted) setState(() => _status = updated);
      if (mounted) _snack('Saved.');
    } on DioException catch (e) {
      if (mounted) _snack(_messageFrom(e));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _disconnect() async {
    try {
      await _service.disconnect();
    } on DioException catch (_) {
      // ignore; reload reflects the real state
    }
    await _load();
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    return 'Request failed (${e.response?.statusCode ?? 'network'}).';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mail monitoring'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final status = _status!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: Icon(
            status.connected ? Icons.check_circle : Icons.mark_email_unread_outlined,
            color: status.connected ? Colors.green : null,
          ),
          title: Text(status.connected ? 'Gmail connected' : 'Gmail not connected'),
          subtitle: Text(
            status.connected
                ? 'AIVA can read your inbox to flag important mail.'
                : 'Connect your Gmail so AIVA can watch for important mail.',
          ),
        ),
        const SizedBox(height: 8),
        if (!status.connected)
          FilledButton.icon(
            onPressed: _connect,
            icon: const Icon(Icons.link),
            label: const Text('Connect Gmail'),
          )
        else ...[
          SwitchListTile(
            title: const Text('Monitoring enabled'),
            value: status.enabled,
            onChanged: (v) => setState(() => _status = MailStatus(
                  connected: status.connected,
                  enabled: v,
                  importanceCriteria: status.importanceCriteria,
                )),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _criteriaController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'What counts as important?',
              hintText: 'e.g. messages from my manager, invoices, anything urgent',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _disconnect,
            icon: const Icon(Icons.link_off),
            label: const Text('Disconnect Gmail'),
          ),
        ],
      ],
    );
  }
}
