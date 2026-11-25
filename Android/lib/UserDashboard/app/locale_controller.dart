import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Session-only by default. The host may inject preference persistence.
/// The host owns this controller and must dispose it after its application.
class LocaleController extends ChangeNotifier {
  LocaleController({
    Locale initialLocale = const Locale('en'),
    this.savePreference,
  }) : _locale = supportedLocales.firstWhere(
         (item) => item.languageCode == initialLocale.languageCode,
         orElse: () => supportedLocales.first,
       );

  static const supportedLocales = [Locale('en'), Locale('ms'), Locale('zh')];
  final Future<void> Function(Locale locale)? savePreference;
  Locale _locale;
  bool _saving = false;
  bool _disposed = false;
  Locale get locale => _locale;
  bool get saving => _saving;
  bool get persistsPreference => savePreference != null;

  Future<void> select(Locale value) async {
    if (_saving || value == _locale) return;
    if (!supportedLocales.contains(value)) throw ArgumentError.value(value);
    _saving = true;
    notifyListeners();
    try {
      await savePreference?.call(value);
      if (!_disposed) _locale = value;
    } finally {
      if (!_disposed) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Small standard Localizations delegate, scoped to the five student features.
/// Replace with the team's generated ARB resources when that contract exists.
class CampusStrings {
  const CampusStrings(this.locale, [this.material]);
  final Locale locale;
  final MaterialLocalizations? material;
  static const delegate = _CampusStringsDelegate();
  static CampusStrings of(BuildContext context) => CampusStrings(
    Localizations.localeOf(context),
    MaterialLocalizations.of(context),
  );

  String t(String key) {
    final values = translations[key];
    assert(values != null, 'Missing CampusSafe translation: $key');
    final index = switch (locale.languageCode) {
      'ms' => 1,
      'zh' => 2,
      _ => 0,
    };
    return values?[index] ?? key;
  }

  String date(DateTime value, {bool time = true, bool showZone = false}) {
    final local = value.toLocal();
    if (material case final formatter?) {
      final date = formatter.formatShortDate(local);
      final offset = local.timeZoneOffset;
      final zone =
          'UTC${offset.isNegative ? '-' : '+'}${offset.inHours.abs().toString().padLeft(2, '0')}:${(offset.inMinutes.abs() % 60).toString().padLeft(2, '0')}';
      return time
          ? '$date · ${formatter.formatTimeOfDay(TimeOfDay.fromDateTime(local))}${showZone ? ' ($zone)' : ''}'
          : date;
    }
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    return time
        ? '$date · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}'
        : date;
  }

  static const Map<String, List<String>> translations = {
    'appearance': ['Appearance', 'Penampilan', '外观'],
    'blockSender': ['Block sender', 'Sekat penghantar', '屏蔽发送者'],
    'blockBody': [
      'Block this sender through your campus moderation service?',
      'Sekat penghantar ini melalui perkhidmatan moderasi kampus?',
      '通过校园内容管理服务屏蔽此发送者？',
    ],
    'blocked': ['Sender blocked', 'Penghantar disekat', '已屏蔽发送者'],
    'blockUnavailable': [
      'Blocking is not connected yet.',
      'Fungsi sekatan belum disambungkan.',
      '屏蔽功能尚未连接。',
    ],
    'offline': [
      'Offline · showing saved data',
      'Luar talian · data tersimpan dipaparkan',
      '离线 · 正在显示已保存的数据',
    ],
    'themeSystem': ['Use device setting', 'Ikut tetapan peranti', '跟随系统'],
    'themeLight': ['Light', 'Cerah', '浅色'],
    'themeDark': ['Dark', 'Gelap', '深色'],
    'preferenceError': [
      'Could not save. Please try again.',
      'Tidak dapat menyimpan. Sila cuba lagi.',
      '无法保存，请重试。',
    ],
    'reportIncident': ['Report an incident', 'Laporkan insiden', '报告事件'],
    'reportNotConnected': [
      'Incident reporting is not connected yet.',
      'Pelaporan insiden belum disambungkan.',
      '事件报告功能尚未连接。',
    ],
    'getHelp': ['Get help', 'Dapatkan bantuan', '寻求帮助'],
    'helpTitle': ['Safety support', 'Sokongan keselamatan', '安全支持'],
    'helpBody': [
      'In immediate danger, move to a safer place if you can and contact local emergency services. CampusSafe chat and incident reports are not emergency response channels.',
      'Jika dalam bahaya segera, pergi ke tempat lebih selamat jika boleh dan hubungi perkhidmatan kecemasan tempatan. Sembang dan laporan CampusSafe bukan saluran respons kecemasan.',
      '如面临紧急危险，请在条件允许时转移到安全地点，并联系当地紧急服务。CampusSafe 聊天和事件报告不是紧急响应渠道。',
    ],
    'contactsUnavailable': [
      'Verified campus contact details have not been supplied yet.',
      'Maklumat hubungan kampus yang disahkan belum diberikan.',
      '尚未提供经确认的校园联系方式。',
    ],
    'latestReport': [
      'Latest report update',
      'Kemas kini laporan terkini',
      '最新报告动态',
    ],
    'searchReports': [
      'Search title or report ID',
      'Cari tajuk atau ID laporan',
      '搜索标题或报告编号',
    ],
    'matchingReports': ['Matching reports', 'Laporan sepadan', '匹配报告'],
    'refreshFailed': [
      'Could not refresh. Showing previous data.',
      'Tidak dapat memuat semula. Data sebelumnya dipaparkan.',
      '刷新失败，正在显示之前的数据。',
    ],
    'lastUpdated': ['Last updated', 'Terakhir dikemas kini', '上次更新'],
    'today': ['Today', 'Hari ini', '今天'],
    'yesterday': ['Yesterday', 'Semalam', '昨天'],
    'newMessages': ['New messages', 'Mesej baharu', '新消息'],
    'sending': ['Sending…', 'Sedang menghantar…', '正在发送…'],
    'pointsGuide': ['How points work', 'Cara mata diberikan', '积分规则'],
    'pointsGuideBody': [
      'Recognise verified, constructive contributions, such as useful safety feedback and confirmed improvements. Report volume alone earns no points. Duplicate, false, or excessive reports must not be rewarded. Final points and rankings are supplied by the campus scoring service.',
      'Hargai sumbangan membina yang disahkan seperti maklum balas keselamatan berguna dan penambahbaikan yang disahkan. Jumlah laporan sahaja tidak mendapat mata. Laporan pendua, palsu atau berlebihan tidak diberi ganjaran. Mata dan kedudukan akhir dibekalkan oleh perkhidmatan pemarkahan kampus.',
      '认可经核实的建设性贡献，例如有用的安全反馈和已确认的改善。报告数量本身不获得积分。重复、虚假或过量报告不应受到奖励。最终积分与排名由校园评分服务提供。',
    ],
    'privacy': ['Privacy and safety', 'Privasi dan keselamatan', '隐私与安全'],
    'privacyBody': [
      'Use a privacy-safe display name in public spaces. Keep names, contact details, exact routines and sensitive incident information out of community chat. Your reports should only be available to you and authorised campus staff.',
      'Gunakan nama paparan yang menjaga privasi di ruang awam. Jangan kongsi nama, maklumat hubungan, rutin tepat dan butiran insiden sensitif dalam sembang komuniti. Laporan anda hanya patut tersedia kepada anda dan kakitangan kampus yang dibenarkan.',
      '在公共空间使用保护隐私的显示名称。不要在社区聊天中分享姓名、联系方式、具体行程或敏感事件信息。您的报告应仅对您和获授权的校园工作人员可见。',
    ],
    'home': ['Home', 'Utama', '首页'],
    'reports': ['My Reports', 'Laporan Saya', '我的报告'],
    'chat': ['Chat', 'Sembang', '聊天'],
    'ranking': ['Ranking', 'Kedudukan', '排名'],
    'language': ['Language settings', 'Tetapan bahasa', '语言设置'],
    'settings': ['Settings', 'Tetapan', '设置'],
    'userName': ['Display name', 'Nama paparan', '姓名'],
    'editName': ['Edit name', 'Sunting nama', '修改姓名'],
    'save': ['Save', 'Simpan', '保存'],
    'nameRequired': [
      'Please enter your name.',
      'Sila masukkan nama anda.',
      '请输入姓名。',
    ],
    'nameInvalid': [
      'Use 1–60 characters on one line.',
      'Gunakan 1–60 aksara dalam satu baris.',
      '请使用 1–60 个字符，且不要换行。',
    ],
    'nameUpdated': ['Name updated', 'Nama dikemas kini', '姓名已更新'],
    'nameSaveError': [
      'Could not save your name. Please try again.',
      'Tidak dapat menyimpan nama. Sila cuba lagi.',
      '无法保存姓名，请重试。',
    ],
    'welcome': ['Welcome,', 'Selamat datang,', '欢迎，'],
    'signingOut': ['Signing out…', 'Sedang log keluar…', '正在退出…'],
    'topContributors': ['Top contributors', 'Penyumbang teratas', '优秀贡献者'],
    'leaderboard': ['Leaderboard', 'Papan kedudukan', '贡献排行榜'],
    'signOut': ['Sign out', 'Log keluar', '退出登录'],
    'signOutTitle': [
      'Sign out of CampusSafe?',
      'Log keluar daripada CampusSafe?',
      '退出 CampusSafe？',
    ],
    'signOutBody': [
      'Your account session is managed by your campus authentication service.',
      'Sesi akaun anda diurus oleh perkhidmatan pengesahan kampus.',
      '您的账户会话由校园身份验证服务管理。',
    ],
    'signOutUnavailable': [
      'Sign-out integration is not connected in this prototype.',
      'Log keluar belum disambungkan dalam prototaip ini.',
      '此原型尚未连接退出登录功能。',
    ],
    'signOutError': [
      'Could not sign out. Please try again.',
      'Tidak dapat log keluar. Sila cuba lagi.',
      '无法退出登录，请重试。',
    ],
    'cancel': ['Cancel', 'Batal', '取消'],
    'close': ['Close', 'Tutup', '关闭'],
    'retry': ['Retry', 'Cuba lagi', '重试'],
    'studentSpace': ['YOUR CAMPUS, TOGETHER', 'KAMPUS KITA, BERSAMA', '共建安全校园'],
    'dashboardTitle': [
      'A safer campus starts with us.',
      'Kampus lebih selamat bermula dengan kita.',
      '安全校园，从我们做起。',
    ],
    'dashboardSubtitle': [
      'Stay informed. Support your community.',
      'Kekal peka. Sokong komuniti anda.',
      '关注校园，守护社区。',
    ],
    'map': ['Campus Map', 'Peta Kampus', '校园地图'],
    'mapPlaceholder': [
      'Your campus at a glance',
      'Kampus anda sepintas lalu',
      '校园概览',
    ],
    'mapDescription': [
      'Interactive map coming with campus integration.',
      'Peta interaktif akan tersedia selepas integrasi kampus.',
      '交互地图将在校园服务接入后提供。',
    ],
    'quickAccess': ['Your student space', 'Ruang pelajar anda', '学生空间'],
    'viewReports': ['Track your reports', 'Jejak laporan anda', '跟踪您的报告'],
    'joinChat': ['Connect with students', 'Berhubung dengan pelajar', '与同学交流'],
    'viewRanking': [
      'Recognize positive impact',
      'Hargai sumbangan positif',
      '认可积极贡献',
    ],
    'demo': [
      'Student UI prototype · fictional data',
      'Prototaip UI pelajar · data rekaan',
      '学生界面原型 · 虚构数据',
    ],
    'reportsTitle': [
      'Track your reports',
      'Suara anda. Kemajuan nyata.',
      '您的反馈，进展可见。',
    ],
    'reportsSubtitle': [
      'Follow your reports and understand their progress.',
      'Ikuti laporan anda dan fahami kemajuannya.',
      '查看您的报告并了解处理进度。',
    ],
    'overview': ['Overview', 'Ringkasan', '概览'],
    'history': ['History', 'Sejarah', '历史'],
    'total': ['Submitted', 'Dihantar', '已提交'],
    'pending': ['Pending', 'Menunggu', '待处理'],
    'inProgress': ['In Progress', 'Dalam Proses', '处理中'],
    'resolved': ['Resolved', 'Diselesaikan', '已解决'],
    'rejected': ['Rejected', 'Ditolak', '已拒绝'],
    'failed': ['Failed to Submit', 'Gagal Dihantar', '提交失败'],
    'draft': ['Draft', 'Draf', '草稿'],
    'resolution': [
      'Resolution of your reports',
      'Penyelesaian laporan anda',
      '您的报告解决率',
    ],
    'resolutionFormula': [
      'Resolved ÷ successfully submitted × 100. Rejected reports are included; drafts and technical failures are excluded.',
      'Diselesaikan ÷ berjaya dihantar × 100. Laporan ditolak dikira; draf dan kegagalan teknikal dikecualikan.',
      '已解决 ÷ 成功提交 × 100。包含已拒绝报告，不包含草稿和技术性提交失败。',
    ],
    'ofSubmitted': [
      'resolved / successfully submitted',
      'diselesaikan / berjaya dihantar',
      '已解决 / 成功提交',
    ],
    'filtered': [
      'Summary follows the filters below.',
      'Ringkasan mengikut penapis di bawah.',
      '概览使用下方筛选条件。',
    ],
    'statusBreakdown': ['Report progress', 'Kemajuan laporan', '报告进度'],
    'filters': ['Filter your reports', 'Tapis laporan anda', '筛选报告'],
    'status': ['Status', 'Status', '状态'],
    'category': ['Category', 'Kategori', '类别'],
    'all': ['All', 'Semua', '全部'],
    'sort': ['Sort', 'Susun', '排序'],
    'newest': ['Newest first', 'Terbaharu dahulu', '最新优先'],
    'oldest': ['Oldest first', 'Terlama dahulu', '最早优先'],
    'dateRange': ['Date range', 'Julat tarikh', '日期范围'],
    'clearFilters': ['Clear filters', 'Kosongkan penapis', '清除筛选'],
    'lighting': ['Lighting', 'Pencahayaan', '照明'],
    'facilities': ['Facilities', 'Kemudahan', '设施'],
    'access': ['Accessibility', 'Kebolehcapaian', '无障碍设施'],
    'environment': ['Environment', 'Persekitaran', '环境'],
    'attachment': ['Attachment recorded', 'Lampiran direkodkan', '有附件记录'],
    'noAttachment': ['No attachments', 'Tiada lampiran', '无附件'],
    'attachmentDemo': [
      'Demo attachment indicator only. No image is stored or downloaded.',
      'Penunjuk lampiran demo sahaja. Tiada imej disimpan atau dimuat turun.',
      '仅为演示附件标识，未存储或下载图片。',
    ],
    'latestUpdate': ['Latest update', 'Kemas kini terkini', '最新进展'],
    'submittedAt': ['Submitted', 'Dihantar', '提交时间'],
    'reportDetails': ['Report details', 'Butiran laporan', '报告详情'],
    'description': ['Description', 'Penerangan', '描述'],
    'location': ['Location', 'Lokasi', '地点'],
    'timeline': ['Status timeline', 'Garis masa status', '状态时间线'],
    'noReports': [
      'No reports to show',
      'Tiada laporan untuk dipaparkan',
      '暂无报告',
    ],
    'noReportsBody': [
      'Try changing your filters. Only reports belonging to the current student are displayed.',
      'Cuba ubah penapis. Hanya laporan milik pelajar semasa dipaparkan.',
      '请尝试调整筛选条件。此处仅显示当前学生的报告。',
    ],
    'noSubmitted': [
      'No successfully submitted reports',
      'Tiada laporan berjaya dihantar',
      '暂无成功提交的报告',
    ],
    'loadReports': [
      'Loading your reports',
      'Memuatkan laporan anda',
      '正在加载您的报告',
    ],
    'loadError': [
      'Unable to load this information',
      'Tidak dapat memuatkan maklumat ini',
      '无法加载此信息',
    ],
    'tryAgain': [
      'Please try again when the service is available.',
      'Sila cuba lagi apabila perkhidmatan tersedia.',
      '服务可用时请重试。',
    ],
    'technicalNotice': [
      'Submission attempts are separate from incident processing. A failed attempt is not a submitted report.',
      'Percubaan penghantaran berasingan daripada pemprosesan insiden. Percubaan gagal bukan laporan dihantar.',
      '提交尝试与事件处理分开记录，失败尝试不属于已提交报告。',
    ],
    'community': ['COMMUNITY', 'KOMUNITI', '社区'],
    'chatTitle': ['Campus safety circle', 'Ruang keselamatan kampus', '校园安全交流'],
    'chatSubtitle': [
      'A considerate space for a safer campus.',
      'Ruang saling menghormati untuk kampus lebih selamat.',
      '友善交流，共建安全校园。',
    ],
    'guidelines': ['Community guidelines', 'Panduan komuniti', '社区准则'],
    'ruleRespect': [
      'Be respectful. No harassment, threats, or spam.',
      'Hormati orang lain. Tiada gangguan, ancaman atau spam.',
      '尊重他人，禁止骚扰、威胁或刷屏。',
    ],
    'rulePrivacy': [
      'Never share student IDs, phone numbers, or private personal information.',
      'Jangan kongsi ID pelajar, nombor telefon atau maklumat peribadi.',
      '切勿分享学号、电话号码或私人信息。',
    ],
    'ruleIncidents': [
      'Do not post sensitive incident details or identify affected people without permission.',
      'Jangan siarkan butiran insiden sensitif atau identiti individu tanpa izin.',
      '未经允许，不得发布敏感事件详情或当事人身份。',
    ],
    'ruleEmergency': [
      'This chat is not monitored as an emergency channel. Use your campus emergency procedures for urgent help.',
      'Sembang ini bukan saluran kecemasan yang dipantau. Ikuti prosedur kecemasan kampus untuk bantuan segera.',
      '此聊天并非受监控的紧急求助渠道。紧急情况请遵循校园应急流程。',
    ],
    'chatDemo': [
      'Local demo only. Messages stay in memory, are not delivered to other students, and disappear when the app restarts.',
      'Demo setempat sahaja. Mesej dalam memori, tidak dihantar kepada pelajar lain dan hilang apabila aplikasi dimulakan semula.',
      '仅限本地演示。消息保存在内存中，不会发送给其他学生，重启应用后消失。',
    ],
    'messageHint': [
      'Write a respectful message…',
      'Tulis mesej yang sopan…',
      '请友善留言…',
    ],
    'send': ['Send message', 'Hantar mesej', '发送消息'],
    'you': ['You', 'Anda', '您'],
    'localOnly': ['Local demo', 'Demo setempat', '本地演示'],
    'reportMessage': ['Report message', 'Laporkan mesej', '举报消息'],
    'reportMessageTitle': [
      'Report this message?',
      'Laporkan mesej ini?',
      '举报此消息？',
    ],
    'reportMessageBody': [
      'A connected moderation service can review this message. Do not include additional private details.',
      'Perkhidmatan moderasi yang disambungkan boleh menyemak mesej ini. Jangan sertakan butiran peribadi tambahan.',
      '接入审核服务后可审查此消息。请勿附加私人信息。',
    ],
    'reportUnavailable': [
      'Demo only: no moderation service is connected. No report was sent.',
      'Demo sahaja: tiada perkhidmatan moderasi disambungkan. Tiada laporan dihantar.',
      '仅为演示：尚未接入审核服务，未发送举报。',
    ],
    'reportReceived': [
      'Message report submitted to the connected service.',
      'Laporan mesej dihantar ke perkhidmatan yang disambungkan.',
      '消息举报已提交至所连接的服务。',
    ],
    'messageFailed': [
      'Message could not be sent. Your text has been kept.',
      'Mesej tidak dapat dihantar. Teks anda dikekalkan.',
      '消息发送失败，已保留您的文字。',
    ],
    'noMessages': [
      'Start a thoughtful conversation',
      'Mulakan perbualan yang bermanfaat',
      '开启友善交流',
    ],
    'noMessagesBody': [
      'Share a constructive campus safety tip without personal details.',
      'Kongsi tip keselamatan kampus tanpa butiran peribadi.',
      '分享有益的校园安全建议，请勿包含私人信息。',
    ],
    'loadingMessages': [
      'Loading conversation',
      'Memuatkan perbualan',
      '正在加载对话',
    ],
    'positiveImpact': [
      'POSITIVE CAMPUS IMPACT',
      'IMPAK POSITIF KAMPUS',
      '校园积极贡献',
    ],
    'rankingTitle': [
      'Small actions. Shared safety.',
      'Tindakan kecil. Keselamatan bersama.',
      '点滴行动，共享安全。',
    ],
    'rankingSubtitle': [
      'Recognizing verified, constructive contributions.',
      'Menghargai sumbangan membina yang disahkan.',
      '认可经过核实的建设性贡献。',
    ],
    'rankingDemo': [
      'Fictional rankings. Points represent verified constructive contributions, never report volume. No points are awarded by this app.',
      'Kedudukan rekaan. Mata mewakili sumbangan membina yang disahkan, bukan jumlah laporan. Aplikasi ini tidak memberi mata.',
      '虚构排名。积分代表经核实的建设性贡献，与报告数量无关。本应用不会自动奖励积分。',
    ],
    'monthly': ['Monthly', 'Bulanan', '本月'],
    'allTime': ['All time', 'Sepanjang masa', '全部时间'],
    'points': ['points', 'mata', '积分'],
    'contributions': ['verified contributions', 'sumbangan disahkan', '已核实贡献'],
    'yourPosition': ['Your position', 'Kedudukan anda', '您的排名'],
    'communityRanking': ['Community ranking', 'Kedudukan komuniti', '社区排名'],
    'notRanked': [
      'Not ranked in this period',
      'Belum disenaraikan dalam tempoh ini',
      '本期暂无排名',
    ],
    'noRanking': ['No rankings yet', 'Belum ada kedudukan', '暂无排名'],
    'noRankingBody': [
      'Verified contributions will appear here when provided by the campus service.',
      'Sumbangan disahkan akan muncul apabila disediakan oleh perkhidmatan kampus.',
      '校园服务提供核实贡献后将在此显示。',
    ],
    'loadingRanking': ['Loading rankings', 'Memuatkan kedudukan', '正在加载排名'],
    'preferences': ['YOUR PREFERENCES', 'PILIHAN ANDA', '您的偏好'],
    'languageTitle': [
      'Feel at home.',
      'Rasa seperti di rumah.',
      '熟悉的语言，亲切的体验。',
    ],
    'languageSubtitle': [
      'Choose the language for your student space.',
      'Pilih bahasa untuk ruang pelajar anda.',
      '选择学生空间的显示语言。',
    ],
    'currentLanguage': ['Current language', 'Bahasa semasa', '当前语言'],
    'selected': ['Selected', 'Dipilih', '已选择'],
    'sessionLanguage': [
      'Applies to these five student pages for this session. Restarting returns to English. Other team modules and user-written content are not translated.',
      'Digunakan pada lima halaman pelajar untuk sesi ini. Mula semula kembali ke bahasa Inggeris. Modul lain dan kandungan pengguna tidak diterjemahkan.',
      '仅适用于本次会话的五个学生页面，重启后恢复英语。其他团队模块和用户内容不会翻译。',
    ],
    'savedLanguage': [
      'Preference is saved by the connected host. User-written content is not translated.',
      'Pilihan disimpan oleh aplikasi hos. Kandungan pengguna tidak diterjemahkan.',
      '偏好由所连接的主应用保存，用户内容不会翻译。',
    ],
    'languageChanged': ['Language updated', 'Bahasa dikemas kini', '语言已更新'],
    'languageError': [
      'Could not save language. Your previous selection is unchanged.',
      'Tidak dapat menyimpan bahasa. Pilihan sebelumnya dikekalkan.',
      '无法保存语言，已保留之前的选择。',
    ],
    'saving': ['Saving…', 'Menyimpan…', '正在保存…'],
  };
}

class _CampusStringsDelegate extends LocalizationsDelegate<CampusStrings> {
  const _CampusStringsDelegate();
  @override
  bool isSupported(Locale locale) => LocaleController.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );
  @override
  Future<CampusStrings> load(Locale locale) =>
      SynchronousFuture(CampusStrings(locale));
  @override
  bool shouldReload(_CampusStringsDelegate old) => false;
}
