import 'package:flutter/material.dart';

/// Curated Material rounded icons — same [IconData.codePoint] + Material font as the rest of the app.
class _IconChoice {
  const _IconChoice(this.icon, this.keywords);
  final IconData icon;
  final String keywords;
}

class _IconGroup {
  const _IconGroup(this.title, this.choices);
  final String title;
  final List<_IconChoice> choices;

  bool matches(String q) {
    if (q.isEmpty) return true;
    final s = q.toLowerCase();
    if (title.toLowerCase().contains(s)) return true;
    return choices.any((c) => c.keywords.contains(s));
  }

  List<_IconChoice> filtered(String q) {
    if (q.isEmpty) return choices;
    final s = q.toLowerCase();
    return choices
        .where(
          (c) =>
              c.keywords.contains(s) || title.toLowerCase().contains(s),
        )
        .toList();
  }
}

/// Hand-picked set: one glyph per idea, Material rounded (M3), searchable by category + keywords.
const List<_IconGroup> _kGroups = [
  _IconGroup('General', [
    _IconChoice(Icons.dashboard_rounded, 'dashboard home overview'),
    _IconChoice(Icons.star_rounded, 'star favorite important'),
    _IconChoice(Icons.bookmark_rounded, 'bookmark save pin'),
    _IconChoice(Icons.label_rounded, 'label tag'),
    _IconChoice(Icons.flag_rounded, 'flag milestone goal'),
    _IconChoice(Icons.inbox_rounded, 'inbox tray'),
    _IconChoice(Icons.archive_rounded, 'archive storage'),
    _IconChoice(Icons.delete_outline_rounded, 'delete trash remove'),
    _IconChoice(Icons.notifications_rounded, 'notifications bell alert'),
    _IconChoice(Icons.grid_view_rounded, 'grid tiles layout'),
    _IconChoice(Icons.view_list_rounded, 'list rows'),
    _IconChoice(Icons.filter_list_rounded, 'filter sort'),
    _IconChoice(Icons.link_rounded, 'link url chain'),
    _IconChoice(Icons.attach_file_rounded, 'attach paperclip file'),
    _IconChoice(Icons.content_copy_rounded, 'copy duplicate'),
    _IconChoice(Icons.share_rounded, 'share send'),
    _IconChoice(Icons.print_rounded, 'print printer'),
    _IconChoice(Icons.info_rounded, 'info help about'),
    _IconChoice(Icons.help_outline_rounded, 'help question'),
    _IconChoice(Icons.warning_rounded, 'warning caution'),
    _IconChoice(Icons.check_circle_rounded, 'check done success'),
    _IconChoice(Icons.radio_button_checked_rounded, 'radio select option'),
    _IconChoice(Icons.more_horiz_rounded, 'more menu dots'),
    _IconChoice(Icons.search_rounded, 'search find magnify'),
  ]),
  _IconGroup('Work & productivity', [
    _IconChoice(Icons.work_rounded, 'work job office'),
    _IconChoice(Icons.business_center_rounded, 'business briefcase'),
    _IconChoice(Icons.laptop_rounded, 'laptop computer'),
    _IconChoice(Icons.smartphone_rounded, 'phone mobile'),
    _IconChoice(Icons.mail_rounded, 'mail email'),
    _IconChoice(Icons.calendar_today_rounded, 'calendar date schedule'),
    _IconChoice(Icons.event_rounded, 'event meeting'),
    _IconChoice(Icons.task_alt_rounded, 'task done check'),
    _IconChoice(Icons.checklist_rounded, 'checklist list todo'),
    _IconChoice(Icons.folder_rounded, 'folder files'),
    _IconChoice(Icons.description_rounded, 'document file notes'),
    _IconChoice(Icons.edit_note_rounded, 'edit write notes'),
    _IconChoice(Icons.schedule_rounded, 'schedule clock time'),
    _IconChoice(Icons.assignment_rounded, 'assignment task project'),
    _IconChoice(Icons.video_call_rounded, 'video call zoom meet'),
    _IconChoice(Icons.call_rounded, 'call phone dial'),
    _IconChoice(Icons.chat_rounded, 'chat message bubble'),
    _IconChoice(Icons.forum_rounded, 'forum discussion thread'),
    _IconChoice(Icons.cloud_done_rounded, 'cloud sync saved'),
    _IconChoice(Icons.upload_file_rounded, 'upload file import'),
    _IconChoice(Icons.download_rounded, 'download export save'),
    _IconChoice(Icons.table_chart_rounded, 'table spreadsheet data'),
    _IconChoice(Icons.bar_chart_rounded, 'bar chart graph'),
    _IconChoice(Icons.pie_chart_rounded, 'pie chart stats'),
    _IconChoice(Icons.insights_rounded, 'insights analytics trend'),
    _IconChoice(Icons.timer_rounded, 'timer stopwatch pomodoro'),
    _IconChoice(Icons.alarm_rounded, 'alarm clock wake'),
    _IconChoice(Icons.event_note_rounded, 'event note agenda'),
    _IconChoice(Icons.sticky_note_2_rounded, 'sticky note memo'),
  ]),
  _IconGroup('Learning & ideas', [
    _IconChoice(Icons.school_rounded, 'school study learn'),
    _IconChoice(Icons.menu_book_rounded, 'book read'),
    _IconChoice(Icons.lightbulb_rounded, 'lightbulb idea'),
    _IconChoice(Icons.psychology_rounded, 'psychology mind focus'),
    _IconChoice(Icons.science_rounded, 'science lab'),
    _IconChoice(Icons.calculate_rounded, 'calculate math'),
    _IconChoice(Icons.auto_stories_rounded, 'stories article'),
    _IconChoice(Icons.biotech_rounded, 'biotech dna research'),
    _IconChoice(Icons.engineering_rounded, 'engineering stem build'),
    _IconChoice(Icons.history_edu_rounded, 'history education'),
    _IconChoice(Icons.quiz_rounded, 'quiz test exam'),
    _IconChoice(Icons.model_training_rounded, 'model ai learning'),
    _IconChoice(Icons.extension_rounded, 'extension puzzle piece'),
    _IconChoice(Icons.rule_folder_rounded, 'rule policy guideline'),
    _IconChoice(Icons.translate_rounded, 'translate language'),
    _IconChoice(Icons.public_rounded, 'public globe world'),
  ]),
  _IconGroup('Creative & media', [
    _IconChoice(Icons.palette_rounded, 'palette art design color'),
    _IconChoice(Icons.brush_rounded, 'brush paint draw'),
    _IconChoice(Icons.music_note_rounded, 'music audio'),
    _IconChoice(Icons.movie_rounded, 'movie video film'),
    _IconChoice(Icons.photo_camera_rounded, 'camera photo'),
    _IconChoice(Icons.image_rounded, 'image picture'),
    _IconChoice(Icons.mic_rounded, 'mic voice record'),
    _IconChoice(Icons.headphones_rounded, 'headphones listen'),
    _IconChoice(Icons.videocam_rounded, 'video camera record'),
    _IconChoice(Icons.library_music_rounded, 'library music album'),
    _IconChoice(Icons.theater_comedy_rounded, 'theater drama comedy'),
    _IconChoice(Icons.color_lens_rounded, 'color lens filter'),
    _IconChoice(Icons.design_services_rounded, 'design services creative'),
    _IconChoice(Icons.architecture_rounded, 'architecture blueprint'),
    _IconChoice(Icons.animation_rounded, 'animation motion'),
    _IconChoice(Icons.slideshow_rounded, 'slideshow presentation'),
    _IconChoice(Icons.audiotrack_rounded, 'audio track waveform'),
    _IconChoice(Icons.graphic_eq_rounded, 'equalizer audio levels'),
  ]),
  _IconGroup('Health & movement', [
    _IconChoice(Icons.fitness_center_rounded, 'gym fitness strength'),
    _IconChoice(Icons.directions_run_rounded, 'run jog exercise'),
    _IconChoice(Icons.self_improvement_rounded, 'meditation calm'),
    _IconChoice(Icons.spa_rounded, 'spa wellness relax'),
    _IconChoice(Icons.local_hospital_rounded, 'health hospital medical'),
    _IconChoice(Icons.monitor_heart_rounded, 'heart health vitals'),
    _IconChoice(Icons.healing_rounded, 'healing recovery care'),
    _IconChoice(Icons.medication_rounded, 'medication pills pharmacy'),
    _IconChoice(Icons.emergency_rounded, 'emergency urgent help'),
    _IconChoice(Icons.accessibility_new_rounded, 'accessibility inclusive'),
    _IconChoice(Icons.sports_soccer_rounded, 'soccer football sport'),
    _IconChoice(Icons.sports_basketball_rounded, 'basketball sport'),
    _IconChoice(Icons.sports_tennis_rounded, 'tennis sport racket'),
    _IconChoice(Icons.pool_rounded, 'pool swim water'),
    _IconChoice(Icons.hiking_rounded, 'hiking trail outdoor'),
    _IconChoice(Icons.snowboarding_rounded, 'snowboard winter sport'),
    _IconChoice(Icons.kayaking_rounded, 'kayak paddle water'),
  ]),
  _IconGroup('Nature & home', [
    _IconChoice(Icons.home_rounded, 'home house'),
    _IconChoice(Icons.eco_rounded, 'eco green nature plant'),
    _IconChoice(Icons.park_rounded, 'park trees outdoor'),
    _IconChoice(Icons.water_drop_rounded, 'water drop hydration'),
    _IconChoice(Icons.wb_sunny_rounded, 'sun weather day'),
    _IconChoice(Icons.cloud_rounded, 'cloud weather'),
    _IconChoice(Icons.pets_rounded, 'pets animal dog cat'),
    _IconChoice(Icons.yard_rounded, 'yard garden'),
    _IconChoice(Icons.kitchen_rounded, 'kitchen cook food home'),
    _IconChoice(Icons.forest_rounded, 'forest trees nature'),
    _IconChoice(Icons.cyclone_rounded, 'cyclone storm weather'),
    _IconChoice(Icons.thunderstorm_rounded, 'thunderstorm rain lightning'),
    _IconChoice(Icons.ac_unit_rounded, 'ac cold snowflake'),
    _IconChoice(Icons.mode_night_rounded, 'night moon dark'),
    _IconChoice(Icons.bedtime_rounded, 'bedtime sleep rest'),
    _IconChoice(Icons.grass_rounded, 'grass lawn plant'),
    _IconChoice(Icons.energy_savings_leaf_rounded, 'leaf green energy'),
    _IconChoice(Icons.tsunami_rounded, 'wave ocean water'),
    _IconChoice(Icons.umbrella_rounded, 'umbrella rain'),
  ]),
  _IconGroup('Food & places', [
    _IconChoice(Icons.restaurant_rounded, 'restaurant food meal'),
    _IconChoice(Icons.local_cafe_rounded, 'cafe coffee tea'),
    _IconChoice(Icons.cake_rounded, 'cake dessert'),
    _IconChoice(Icons.shopping_cart_rounded, 'cart shop buy'),
    _IconChoice(Icons.storefront_rounded, 'store market'),
    _IconChoice(Icons.flight_rounded, 'flight plane travel'),
    _IconChoice(Icons.train_rounded, 'train transit'),
    _IconChoice(Icons.directions_car_rounded, 'car drive commute'),
    _IconChoice(Icons.hotel_rounded, 'hotel travel stay'),
    _IconChoice(Icons.map_rounded, 'map location place'),
    _IconChoice(Icons.lunch_dining_rounded, 'lunch dining food'),
    _IconChoice(Icons.dinner_dining_rounded, 'dinner dining food'),
    _IconChoice(Icons.icecream_rounded, 'ice cream dessert'),
    _IconChoice(Icons.local_bar_rounded, 'bar drinks cocktail'),
    _IconChoice(Icons.local_pizza_rounded, 'pizza food'),
    _IconChoice(Icons.ramen_dining_rounded, 'ramen noodle soup'),
    _IconChoice(Icons.bakery_dining_rounded, 'bakery bread pastry'),
    _IconChoice(Icons.liquor_rounded, 'liquor wine bottle'),
    _IconChoice(Icons.luggage_rounded, 'luggage suitcase travel'),
    _IconChoice(Icons.directions_boat_rounded, 'boat ship ferry'),
    _IconChoice(Icons.two_wheeler_rounded, 'bike scooter motorcycle'),
    _IconChoice(Icons.electric_car_rounded, 'electric car ev'),
    _IconChoice(Icons.local_parking_rounded, 'parking lot'),
    _IconChoice(Icons.explore_rounded, 'explore discover compass'),
    _IconChoice(Icons.pin_drop_rounded, 'pin location map'),
  ]),
  _IconGroup('Money & admin', [
    _IconChoice(Icons.payments_rounded, 'payments money pay'),
    _IconChoice(Icons.account_balance_rounded, 'bank finance'),
    _IconChoice(Icons.savings_rounded, 'savings budget'),
    _IconChoice(Icons.receipt_long_rounded, 'receipt invoice'),
    _IconChoice(Icons.trending_up_rounded, 'growth trend stats'),
    _IconChoice(Icons.monetization_on_rounded, 'monetization dollar earn'),
    _IconChoice(Icons.currency_exchange_rounded, 'currency exchange forex'),
    _IconChoice(Icons.credit_card_rounded, 'credit card payment'),
    _IconChoice(Icons.attach_money_rounded, 'money cash dollar'),
    _IconChoice(Icons.request_quote_rounded, 'quote estimate bid'),
    _IconChoice(Icons.price_check_rounded, 'price check deal'),
    _IconChoice(Icons.percent_rounded, 'percent discount rate'),
    _IconChoice(Icons.analytics_rounded, 'analytics chart business'),
    _IconChoice(Icons.account_balance_wallet_rounded, 'wallet balance'),
    _IconChoice(Icons.point_of_sale_rounded, 'pos register checkout'),
  ]),
  _IconGroup('People & social', [
    _IconChoice(Icons.person_rounded, 'person user profile'),
    _IconChoice(Icons.groups_rounded, 'groups team people'),
    _IconChoice(Icons.family_restroom_rounded, 'family home'),
    _IconChoice(Icons.celebration_rounded, 'celebration party'),
    _IconChoice(Icons.volunteer_activism_rounded, 'volunteer charity help'),
    _IconChoice(Icons.handshake_rounded, 'handshake deal partner'),
    _IconChoice(Icons.people_rounded, 'people crowd users'),
    _IconChoice(Icons.diversity_3_rounded, 'diversity inclusion team'),
    _IconChoice(Icons.face_rounded, 'face emoji mood'),
    _IconChoice(Icons.sentiment_satisfied_rounded, 'happy smile satisfied'),
    _IconChoice(Icons.mood_rounded, 'mood feeling'),
    _IconChoice(Icons.support_agent_rounded, 'support help agent'),
    _IconChoice(Icons.connect_without_contact_rounded, 'connect network remote'),
    _IconChoice(Icons.reddit_rounded, 'reddit social forum'),
  ]),
  _IconGroup('Tech & tools', [
    _IconChoice(Icons.computer_rounded, 'computer desktop'),
    _IconChoice(Icons.memory_rounded, 'memory chip tech'),
    _IconChoice(Icons.router_rounded, 'router network wifi'),
    _IconChoice(Icons.code_rounded, 'code developer'),
    _IconChoice(Icons.bug_report_rounded, 'bug issue debug'),
    _IconChoice(Icons.build_rounded, 'build tools fix'),
    _IconChoice(Icons.settings_rounded, 'settings gear'),
    _IconChoice(Icons.storage_rounded, 'storage database disk'),
    _IconChoice(Icons.cloud_queue_rounded, 'cloud server online'),
    _IconChoice(Icons.terminal_rounded, 'terminal shell cli'),
    _IconChoice(Icons.dataset_rounded, 'dataset table data'),
    _IconChoice(Icons.hub_rounded, 'hub network nodes'),
    _IconChoice(Icons.smart_display_rounded, 'smart display assistant'),
    _IconChoice(Icons.devices_rounded, 'devices phone tablet'),
    _IconChoice(Icons.phonelink_rounded, 'phonelink sync mirror'),
    _IconChoice(Icons.cast_rounded, 'cast stream screen'),
    _IconChoice(Icons.security_rounded, 'security lock tech'),
    _IconChoice(Icons.vpn_key_rounded, 'vpn key secure'),
    _IconChoice(Icons.fingerprint_rounded, 'fingerprint biometric auth'),
  ]),
  _IconGroup('Symbols', [
    _IconChoice(Icons.bolt_rounded, 'bolt energy fast'),
    _IconChoice(Icons.rocket_launch_rounded, 'rocket launch ship'),
    _IconChoice(Icons.emoji_events_rounded, 'trophy award win'),
    _IconChoice(Icons.verified_rounded, 'verified check trust'),
    _IconChoice(Icons.favorite_rounded, 'heart love'),
    _IconChoice(Icons.shield_rounded, 'shield security safe'),
    _IconChoice(Icons.lock_rounded, 'lock privacy'),
    _IconChoice(Icons.key_rounded, 'key access'),
    _IconChoice(Icons.add_circle_rounded, 'add plus create'),
    _IconChoice(Icons.remove_circle_rounded, 'remove minus'),
    _IconChoice(Icons.priority_high_rounded, 'priority urgent important'),
    _IconChoice(Icons.new_releases_rounded, 'new releases sparkle'),
    _IconChoice(Icons.auto_awesome_rounded, 'sparkle magic awesome'),
    _IconChoice(Icons.grade_rounded, 'grade star rating'),
    _IconChoice(Icons.military_tech_rounded, 'badge achievement rank'),
    _IconChoice(Icons.workspace_premium_rounded, 'premium crown vip'),
    _IconChoice(Icons.local_fire_department_rounded, 'fire hot trending'),
    _IconChoice(Icons.recycling_rounded, 'recycle sustainability'),
  ]),
  _IconGroup('Sports & games', [
    _IconChoice(Icons.sports_esports_rounded, 'esports gaming controller'),
    _IconChoice(Icons.sports_rounded, 'sports generic'),
    _IconChoice(Icons.sports_baseball_rounded, 'baseball sport'),
    _IconChoice(Icons.sports_football_rounded, 'football sport'),
    _IconChoice(Icons.sports_golf_rounded, 'golf sport'),
    _IconChoice(Icons.sports_hockey_rounded, 'hockey sport'),
    _IconChoice(Icons.sports_martial_arts_rounded, 'martial arts karate'),
    _IconChoice(Icons.sports_motorsports_rounded, 'motorsports racing'),
    _IconChoice(Icons.sports_volleyball_rounded, 'volleyball sport'),
    _IconChoice(Icons.casino_rounded, 'casino dice luck'),
    _IconChoice(Icons.videogame_asset_rounded, 'videogame game asset'),
    _IconChoice(Icons.toys_rounded, 'toys play fun'),
    _IconChoice(Icons.interests_rounded, 'interests puzzle hobby'),
  ]),
];

/// Modern bottom sheet: search, grouped grid, drag handle. Returns selected [IconData] or null.
Future<IconData?> showCategoryIconPicker(BuildContext context) {
  return showModalBottomSheet<IconData>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final h = MediaQuery.sizeOf(sheetContext).height * 0.78;
      return SizedBox(
        height: h,
        child: _CategoryIconPickerBody(
          onChosen: (icon) => Navigator.of(sheetContext).pop(icon),
        ),
      );
    },
  );
}

class _CategoryIconPickerBody extends StatefulWidget {
  const _CategoryIconPickerBody({required this.onChosen});

  final void Function(IconData icon) onChosen;

  @override
  State<_CategoryIconPickerBody> createState() =>
      _CategoryIconPickerBodyState();
}

class _CategoryIconPickerBodyState extends State<_CategoryIconPickerBody> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final q = _search.text.trim();
    final visibleGroups = _kGroups.where((g) => g.matches(q)).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose an icon',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Curated Material icons — search by name or category',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SearchBar(
            controller: _search,
            hintText: 'Search icons…',
            leading: const Icon(Icons.search_rounded),
            trailing: [
              if (q.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _search.clear();
                    setState(() {});
                  },
                ),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: visibleGroups.isEmpty
                ? Center(
                    child: Text(
                      'No icons match “$q”',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: visibleGroups.length,
                    itemBuilder: (context, gi) {
                      final group = visibleGroups[gi];
                      final items = group.filtered(q);
                      if (items.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, ii) {
                                final choice = items[ii];
                                return Material(
                                  color: cs.surfaceContainerHighest
                                      .withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(14),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () =>
                                        widget.onChosen(choice.icon),
                                    child: Icon(
                                      choice.icon,
                                      size: 26,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
