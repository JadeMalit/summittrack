import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class FirstAidEmergencyTips extends StatefulWidget {
  const FirstAidEmergencyTips({super.key});

  @override
  State<FirstAidEmergencyTips> createState() => _FirstAidEmergencyTipsState();
}

class _FirstAidEmergencyTipsState extends State<FirstAidEmergencyTips> {
  int? _openIndex = 0;

  static const _tips = [
    _EmergencyTipItem(
      title: 'Essential first-aid kit to bring before hiking',
      body:
          'Bring adhesive bandages, sterile gauze pads, medical tape, antiseptic wipes, antibacterial ointment, blister pads, elastic bandage, triangular bandage, instant cold pack, tweezers, scissors, disposable gloves, hand sanitizer, sterile saline, burn gel, emergency blanket, thermometer, and a small splint for possible injuries.\n\nFor medicine, bring pain relievers, antihistamine for allergies, anti-diarrheal medicine, antacid, oral rehydration salts, and personal medications such as inhaler or EpiPen if prescribed.\n\nAlso include emergency contact information, a small flashlight or headlamp, whistle, power bank, and check the kit before every hike to make sure nothing is expired.',
    ),
    _EmergencyTipItem(
      title: 'For cuts, wounds, or bleeding',
      body:
          'Clean your hands first or wear disposable gloves. Rinse the wound with clean water or sterile saline. Use antiseptic wipes around the wound area, then cover it with sterile gauze or an adhesive bandage. Apply gentle pressure if there is bleeding. If the bleeding does not stop, the wound is deep, or there is a large injury, seek emergency help immediately.',
    ),
    _EmergencyTipItem(
      title: 'For sprains, strains, or possible fractures',
      body:
          'Stop hiking and rest the injured area. Avoid forcing the person to continue walking. Apply a cold pack wrapped in cloth to reduce swelling. Use an elastic bandage for support but do not wrap it too tightly. If a fracture is suspected, keep the injured part still and use a splint if available. Get help from the guide, organizer, ranger, or emergency responders.',
    ),
    _EmergencyTipItem(
      title: 'For blisters',
      body:
          'Do not pop the blister if it is still closed. Cover it with a blister pad or clean bandage to prevent rubbing. Keep the area clean and dry. Change socks if they are wet. If the blister opens, clean it gently, apply antibacterial ointment, and cover it with sterile gauze or bandage.',
    ),
    _EmergencyTipItem(
      title: 'For heat exhaustion or dehydration',
      body:
          'Move the person to a shaded or cooler area. Let them rest and loosen tight clothing. Give small sips of water or oral rehydration solution. Cool the body using a wet cloth or fan. Symptoms may include heavy sweating, weakness, dizziness, headache, nausea, or muscle cramps. Do not ignore these signs.',
    ),
    _EmergencyTipItem(
      title: 'For heat stroke',
      body:
          'Heat stroke is an emergency. Symptoms may include very high body temperature, confusion, fainting, hot skin, fast heartbeat, or loss of consciousness. Call emergency help immediately. Move the person to shade, cool the body with wet cloths, and do not give food or drink if the person is unconscious or confused.',
    ),
    _EmergencyTipItem(
      title: 'For insect bites or stings',
      body:
          'Move away from the insect area. If there is a visible stinger, remove it carefully using tweezers or by scraping it away. Clean the area with antiseptic wipes or clean water. Apply a cold pack to reduce swelling. Use antihistamine if needed and safe for the person. Watch for serious allergic reactions.',
    ),
    _EmergencyTipItem(
      title: 'For allergic reactions',
      body:
          'Watch for swelling of the face, lips, or throat, difficulty breathing, dizziness, or widespread rashes. If the person has prescribed allergy medicine or an EpiPen, help them use it as instructed. Call emergency help immediately if breathing becomes difficult or symptoms become severe.',
    ),
    _EmergencyTipItem(
      title: 'For snake bites',
      body:
          'Keep the person calm and still. Do not cut the wound, do not suck out venom, and do not apply ice. Remove tight items like rings, bracelets, or watches near the bite area. Keep the bitten part lower than the heart if possible. Call emergency help immediately and go to the nearest medical facility.',
    ),
    _EmergencyTipItem(
      title: 'For fainting or dizziness',
      body:
          'Let the person sit or lie down in a safe place. Raise their legs slightly if possible. Give water only if the person is awake and alert. Check if they are overheating, dehydrated, hungry, or injured. If they do not wake up quickly, have trouble breathing, or faint again, seek emergency help immediately.',
    ),
    _EmergencyTipItem(
      title: 'For burns or sunburn',
      body:
          'Cool the burned area with clean cool water. Do not apply ice directly. Cover the area with clean gauze if needed. For sunburn, move to shade, drink water, and avoid more sun exposure. Seek medical help if the burn is large, severe, blistering badly, or located on the face, hands, or sensitive areas.',
    ),
    _EmergencyTipItem(
      title: 'For hypothermia or extreme cold',
      body:
          'Move the person away from cold, wind, or rain. Remove wet clothing if possible and replace it with dry layers. Cover the person with warm clothes or an emergency blanket. Give warm drinks only if the person is awake and alert. Seek help if the person is confused, shaking badly, very weak, or sleepy.',
    ),
    _EmergencyTipItem(
      title: 'Emergency reminders before and during the hike',
      body:
          'Always hike with a guide, organizer, or group. Check the weather before the hike. Tell someone your hiking plan, trail, and expected return time. Bring enough water, food, first-aid supplies, flashlight, whistle, power bank, rain protection, and warm clothing. Stay on the trail, avoid hiking during bad weather, do not leave trash, and rest when tired. In serious emergencies, contact the guide, local rescue team, park ranger, or emergency hotline immediately.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tipTextStyle = GoogleFonts.merriweather(
      fontSize: 12.8,
      height: 1.6,
      color: colors.textSecondary,
    );

    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? colors.surfaceHigh
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.isDarkMode ? colors.border : const Color(0xFFC7C0B3),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (var index = 0; index < _tips.length; index++) ...[
            _EmergencyTipTile(
              item: _tips[index],
              textStyle: tipTextStyle,
              isOpen: _openIndex == index,
              onTap: () {
                setState(() {
                  _openIndex = _openIndex == index ? null : index;
                });
              },
            ),
            if (index < _tips.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? colors.surface
                  : const Color(0xFFF7F5F1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.isDarkMode
                    ? colors.border
                    : const Color(0xFFCEC6B9),
              ),
            ),
            child: Text(
              'This section is for basic emergency guidance only and does not replace professional medical help.',
              style: GoogleFonts.poppins(
                fontSize: 11.8,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyTipTile extends StatelessWidget {
  const _EmergencyTipTile({
    required this.item,
    required this.textStyle,
    required this.isOpen,
    required this.onTap,
  });

  final _EmergencyTipItem item;
  final TextStyle textStyle;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          color: context.isDarkMode ? colors.surface : const Color(0xFFF7F5F1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.isDarkMode ? colors.border : const Color(0xFFB7B0A4),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            item.title,
                            style: GoogleFonts.fredoka(
                              fontSize: 14.4,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedRotation(
                        turns: isOpen ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (isOpen) ...[
                    Divider(
                      height: 1,
                      color: context.isDarkMode
                          ? colors.divider
                          : const Color(0xFFD5CEC2),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(item.body, style: textStyle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyTipItem {
  const _EmergencyTipItem({required this.title, required this.body});

  final String title;
  final String body;
}
