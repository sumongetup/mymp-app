import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'bn.dart';
import 'models.dart';
import 'theme.dart';

/// A member's photograph, or the first letter of their name on the party's
/// colour when the secretariat has published no picture.
class MemberAvatar extends StatelessWidget {
  final MemberBrief member;
  final double size;
  const MemberAvatar({super.key, required this.member, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final colour = AppColors.party(member.party);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: colour.withValues(alpha: 0.12),
      child: Text(
        initialOf(member.nameBn),
        style: TextStyle(
          fontFamily: 'NotoSansBengali',
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: colour,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: member.photoUrl == null
            ? fallback
            : CachedNetworkImage(
                imageUrl: member.photoUrl!,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 180),
                placeholder: (_, _) => Container(color: AppColors.sunk),
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

/// The party's mark: a coloured dot and its short name, as on the website.
class PartyChip extends StatelessWidget {
  final String? abbr;
  final String? label;
  final bool compact;
  const PartyChip({super.key, this.abbr, this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (abbr == null && label == null) return const SizedBox.shrink();
    final colour = AppColors.party(abbr);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: colour, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label ?? abbr!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'NotoSansBengali',
              fontSize: compact ? 12.5 : 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}

/// A small outlined label: an office, a seat, a category.
class Pill extends StatelessWidget {
  final String text;
  final Color? colour;
  final bool filled;
  const Pill(this.text, {super.key, this.colour, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final c = colour ?? AppColors.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? c : c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: filled ? c : c.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'NotoSansBengali',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: filled ? Colors.white : c,
        ),
      ),
    );
  }
}

/// One member in a list: photograph, name, what they hold, where they sit.
class MemberTile extends StatelessWidget {
  final MemberBrief member;
  final VoidCallback onTap;
  const MemberTile({super.key, required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: Border.all(color: AppColors.rule),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              MemberAvatar(member: member),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.nameBn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(member.seatLabel, style: Theme.of(context).textTheme.bodySmall),
                        if (member.party != null) ...[
                          Text(' · ', style: Theme.of(context).textTheme.bodySmall),
                          Flexible(child: PartyChip(abbr: member.party, label: member.partyBn, compact: true)),
                        ],
                      ],
                    ),
                    if (member.officeBn != null) ...[
                      const SizedBox(height: 6),
                      Pill(member.officeBn!),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a screen shows when it has nothing: a reason and, where there is one,
/// a way out.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.brandSoft, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.brand, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                ),
                child: Text(actionLabel!, style: const TextStyle(fontFamily: 'NotoSansBengali', fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The bar of choices above a list. One row, scrolls sideways when the labels
/// outgrow the screen, which they do on a small phone in Bangla.
class ChipBar extends StatelessWidget {
  final List<({String label, String? value})> options;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const ChipBar({super.key, required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePad),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final o = options[i];
          final on = o.value == selected;
          return GestureDetector(
            onTap: () => onSelect(o.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? AppColors.ink : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(color: on ? AppColors.ink : AppColors.rule),
              ),
              child: Text(
                o.label,
                style: TextStyle(
                  fontFamily: 'NotoSansBengali',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: on ? Colors.white : AppColors.inkSoft,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The message shown when a fetch failed, with the one button that helps.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'তথ্য আনা গেল না',
        body: message,
        actionLabel: 'আবার চেষ্টা করুন',
        onAction: onRetry,
      );
}
