import 'package:flutter/material.dart';

import '../api/model/model.dart';
import '../api/route/messages.dart';
import '../model/emoji.dart';
import 'color.dart';
import 'emoji.dart';
import 'store.dart';
import 'text.dart';

/// Emoji-reaction styles that differ between light and dark themes.
class EmojiReactionTheme extends ThemeExtension<EmojiReactionTheme> {
  EmojiReactionTheme.light() :
    this._(
      bgSelected: Colors.white,

      // TODO shadow effect, following web, which uses `box-shadow: inset`:
      //   https://developer.mozilla.org/en-US/docs/Web/CSS/box-shadow#inset
      //   Needs Flutter support for something like that:
      //     https://github.com/flutter/flutter/issues/18636
      //     https://github.com/flutter/flutter/issues/52999
      //   Until then use a solid color; a much-lightened version of the shadow color.
      //   Also adapt by making [borderUnselected] more transparent, so we'll
      //   want to check that against web when implementing the shadow.
      bgUnselected: const HSLColor.fromAHSL(0.08, 210, 0.50, 0.875).toColor(),

      borderSelected: Colors.black.withValues(alpha: 0.45),

      // TODO see TODO on [bgUnselected] about shadow effect
      borderUnselected: Colors.black.withValues(alpha: 0.05),

      textSelected: const HSLColor.fromAHSL(1, 210, 0.20, 0.20).toColor(),
      textUnselected: const HSLColor.fromAHSL(1, 210, 0.20, 0.25).toColor(),
    );

  EmojiReactionTheme.dark() :
    this._(
      bgSelected: Colors.black.withValues(alpha: 0.8),
      bgUnselected: Colors.black.withValues(alpha: 0.3),
      borderSelected: Colors.white.withValues(alpha: 0.75),
      borderUnselected: Colors.white.withValues(alpha: 0.15),
      textSelected: Colors.white.withValues(alpha: 0.85),
      textUnselected: Colors.white.withValues(alpha: 0.75),
    );

  EmojiReactionTheme._({
    required this.bgSelected,
    required this.bgUnselected,
    required this.borderSelected,
    required this.borderUnselected,
    required this.textSelected,
    required this.textUnselected,
  });

  /// The [EmojiReactionTheme] from the context's active theme.
  ///
  /// The [ThemeData] must include [EmojiReactionTheme] in [ThemeData.extensions].
  static EmojiReactionTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<EmojiReactionTheme>();
    assert(extension != null);
    return extension!;
  }

  final Color bgSelected;
  final Color bgUnselected;
  final Color borderSelected;
  final Color borderUnselected;
  final Color textSelected;
  final Color textUnselected;

  @override
  EmojiReactionTheme copyWith({
    Color? bgSelected,
    Color? bgUnselected,
    Color? borderSelected,
    Color? borderUnselected,
    Color? textSelected,
    Color? textUnselected,
  }) {
    return EmojiReactionTheme._(
      bgSelected: bgSelected ?? this.bgSelected,
      bgUnselected: bgUnselected ?? this.bgUnselected,
      borderSelected: borderSelected ?? this.borderSelected,
      borderUnselected: borderUnselected ?? this.borderUnselected,
      textSelected: textSelected ?? this.textSelected,
      textUnselected: textUnselected ?? this.textUnselected,
    );
  }

  @override
  EmojiReactionTheme lerp(EmojiReactionTheme other, double t) {
    if (identical(this, other)) {
      return this;
    }
    return EmojiReactionTheme._(
      bgSelected: Color.lerp(bgSelected, other.bgSelected, t)!,
      bgUnselected: Color.lerp(bgUnselected, other.bgUnselected, t)!,
      borderSelected: Color.lerp(borderSelected, other.borderSelected, t)!,
      borderUnselected: Color.lerp(borderUnselected, other.borderUnselected, t)!,
      textSelected: Color.lerp(textSelected, other.textSelected, t)!,
      textUnselected: Color.lerp(textUnselected, other.textUnselected, t)!,
    );
  }
}

class ReactionChipsList extends StatelessWidget {
  const ReactionChipsList({
    super.key,
    required this.messageId,
    required this.reactions,
  });

  final int messageId;
  final Reactions reactions;

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final displayEmojiReactionUsers = store.userSettings?.displayEmojiReactionUsers ?? false;
    final showNames = displayEmojiReactionUsers && reactions.total <= 3;

    return Wrap(spacing: 4, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center,
      children: reactions.aggregated.map((reactionVotes) => ReactionChip(
        showName: showNames,
        messageId: messageId, reactionWithVotes: reactionVotes),
      ).toList());
  }
}

class ReactionChip extends StatelessWidget {
  final bool showName;
  final int messageId;
  final ReactionWithVotes reactionWithVotes;

  const ReactionChip({
    super.key,
    required this.showName,
    required this.messageId,
    required this.reactionWithVotes,
  });

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);

    final reactionType = reactionWithVotes.reactionType;
    final emojiCode = reactionWithVotes.emojiCode;
    final emojiName = reactionWithVotes.emojiName;
    final userIds = reactionWithVotes.userIds;

    final selfVoted = userIds.contains(store.selfUserId);
    final label = showName
      // TODO(i18n): List formatting, like you can do in JavaScript:
      //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya', 'Shu'])
      //   // 'Chris、Greg、Alya、Shu'
      ? userIds.map((id) {
          return id == store.selfUserId
            ? 'You'
            : store.users[id]?.fullName ?? '(unknown user)'; // TODO(i18n)
        }).join(', ')
      : userIds.length.toString();

    final reactionTheme = EmojiReactionTheme.of(context);
    final borderColor =     selfVoted ? reactionTheme.borderSelected : reactionTheme.borderUnselected;
    final labelColor =      selfVoted ? reactionTheme.textSelected   : reactionTheme.textUnselected;
    final backgroundColor = selfVoted ? reactionTheme.bgSelected     : reactionTheme.bgUnselected;
    final splashColor =     selfVoted ? reactionTheme.bgUnselected   : reactionTheme.bgSelected;
    final highlightColor =  splashColor.withFadedAlpha(0.5);

    final borderSide = BorderSide(
      color: borderColor,
      width: selfVoted ? 1.5 : 1.0,
    );
    final shape = StadiumBorder(side: borderSide);

    final emojiDisplay = store.emojiDisplayFor(
      emojiType: reactionType,
      emojiCode: emojiCode,
      emojiName: emojiName,
    ).resolve(store.userSettings);

    final emoji = switch (emojiDisplay) {
      UnicodeEmojiDisplay() => _UnicodeEmoji(
        emojiDisplay: emojiDisplay),
      ImageEmojiDisplay() => _ImageEmoji(
        emojiDisplay: emojiDisplay, emojiName: emojiName, selected: selfVoted),
      TextEmojiDisplay() => _TextEmoji(
        emojiDisplay: emojiDisplay, selected: selfVoted),
    };

    return Tooltip(
      // TODO(#434): Semantics with eg "Reaction: <emoji name>; you and N others: <names>"
      excludeFromSemantics: true,
      message: emojiName,
      child: Material(
        color: backgroundColor,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          splashColor: splashColor,
          highlightColor: highlightColor,
          onTap: () {
            (selfVoted ? removeReaction : addReaction).call(store.connection,
              messageId: messageId,
              reactionType: reactionType,
              emojiCode: emojiCode,
              emojiName: emojiName,
            );
          },
          child: Padding(
            // 1px of this padding accounts for the border, which Flutter
            // just paints without changing size.
            padding: const EdgeInsetsDirectional.fromSTEB(4, 3, 5, 3),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxRowWidth = constraints.maxWidth;
                // To give text emojis some room so they need fewer line breaks
                // when the label is long.
                // TODO(#433) This is a bit overzealous. The shorter width
                //   won't be necessary when the text emoji is very short, or
                //   in the near-universal case of small, square emoji (i.e.
                //   Unicode and image emoji). But it's not simple to recognize
                //   those cases here: we don't know at this point whether we'll
                //   be showing a text emoji, because we use that for various
                //   error conditions (including when an image fails to load,
                //   which we learn about especially late).
                final maxLabelWidth = (maxRowWidth - 6) * 0.75; // 6 is padding

                final labelScaler = _labelTextScalerClamped(context);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // So text-emoji chips are at least as tall as square-emoji
                    // ones (probably a good thing).
                    SizedBox(height: _squareEmojiScalerClamped(context).scale(_squareEmojiSize)),
                    Flexible( // [Flexible] to let text emojis expand if they can
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: emoji)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: maxLabelWidth),
                        child: Text(
                          textWidthBasis: TextWidthBasis.longestLine,
                          textScaler: labelScaler,
                          style: TextStyle(
                            fontSize: (14 * 0.90),
                            letterSpacing: proportionalLetterSpacing(context,
                              kButtonTextLetterSpacingProportion,
                              baseFontSize: (14 * 0.90),
                              textScaler: labelScaler),
                            height: 13 / (14 * 0.90),
                            color: labelColor,
                          ).merge(weightVariableTextStyle(context,
                              wght: selfVoted ? 600 : null)),
                          label))),
                  ]);
                })))));
  }
}

/// The size of a square emoji (Unicode or image).
///
/// Should be scaled by [_emojiTextScalerClamped].
const _squareEmojiSize = 17.0;

/// A font size that, with Noto Color Emoji and our line-height config,
/// causes a Unicode emoji to occupy a [_squareEmojiSize] square in the layout.
///
/// Determined experimentally:
///   <https://github.com/zulip/zulip-flutter/pull/410#discussion_r1402808701>
const _notoColorEmojiTextSize = 14.5;

/// A [TextScaler] that limits Unicode and image emojis' max scale factor,
/// to leave space for the label.
///
/// This should scale [_squareEmojiSize] for Unicode and image emojis.
// TODO(a11y) clamp higher?
TextScaler _squareEmojiScalerClamped(BuildContext context) =>
  MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 2);

/// A [TextScaler] that limits text emojis' max scale factor,
/// to minimize the need for line breaks.
// TODO(a11y) clamp higher?
TextScaler _textEmojiScalerClamped(BuildContext context) =>
  MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);

/// A [TextScaler] that limits the label's max scale factor,
/// to minimize the need for line breaks.
// TODO(a11y) clamp higher?
TextScaler _labelTextScalerClamped(BuildContext context) =>
  MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 2);

class _UnicodeEmoji extends StatelessWidget {
  const _UnicodeEmoji({required this.emojiDisplay});

  final UnicodeEmojiDisplay emojiDisplay;

  @override
  Widget build(BuildContext context) {
    return UnicodeEmojiWidget(
      size: _squareEmojiSize,
      notoColorEmojiTextSize: _notoColorEmojiTextSize,
      textScaler: _squareEmojiScalerClamped(context),
      emojiDisplay: emojiDisplay);
  }
}

class _ImageEmoji extends StatelessWidget {
  const _ImageEmoji({
    required this.emojiDisplay,
    required this.emojiName,
    required this.selected,
  });

  final ImageEmojiDisplay emojiDisplay;
  final String emojiName;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ImageEmojiWidget(
      size: _squareEmojiSize,
      // Unicode and text emoji get scaled; it would look weird if image emoji didn't.
      textScaler: _squareEmojiScalerClamped(context),
      emojiDisplay: emojiDisplay,
      errorBuilder: (context, _, __) => _TextEmoji(
        emojiDisplay: TextEmojiDisplay(emojiName: emojiName), selected: selected),
    );
  }
}

class _TextEmoji extends StatelessWidget {
  const _TextEmoji({required this.emojiDisplay, required this.selected});

  final TextEmojiDisplay emojiDisplay;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final emojiName = emojiDisplay.emojiName;

    // Encourage line breaks before "_" (common in these), but try not
    // to leave a colon alone on a line. See:
    //   <https://github.com/flutter/flutter/issues/61081#issuecomment-1103330522>
    final text = ':\ufeff${emojiName.replaceAll('_', '\u200b_')}\ufeff:';

    final reactionTheme = EmojiReactionTheme.of(context);
    return Text(
      textAlign: TextAlign.end,
      textScaler: _textEmojiScalerClamped(context),
      textWidthBasis: TextWidthBasis.longestLine,
      style: TextStyle(
        fontSize: 14 * 0.8,
        height: 1, // to be denser when we have to wrap
        color: selected ? reactionTheme.textSelected : reactionTheme.textUnselected,
      ).merge(weightVariableTextStyle(context,
          wght: selected ? 600 : null)),
      text);
  }
}
