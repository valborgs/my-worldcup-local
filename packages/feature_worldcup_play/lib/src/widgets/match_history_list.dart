import 'package:flutter/material.dart';
import 'package:worldcup_domain/worldcup_domain.dart';
import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import '../state/match_history.dart';
import 'match_history_entry.dart';

const double _avatarSize = 56;

/// 결승부터 첫 '강'까지, 대결을 하나씩 나열한 목록.
class MatchHistoryList extends StatelessWidget {
  final List<MatchStage> stages;

  const MatchHistoryList(this.stages, {super.key});

  @override
  Widget build(BuildContext context) {
    // 제목 줄과 대결 줄을 한 목록으로 펴서 보이는 줄만 만들게 한다.
    final rows = <Object>[
      for (final stage in stages) ...[stage, ...stage.matches],
    ];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return row is MatchStage
            ? _StageHeader(row)
            : _MatchCard(row as MatchRecord);
      },
    );
  }
}

class _StageHeader extends StatelessWidget {
  final MatchStage stage;

  const _StageHeader(this.stage);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          stage.isFinal
              ? l10n.resultHistoryFinal
              : l10n.resultHistoryStage(stage.stage),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchRecord match;

  const _MatchCard(this.match);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 결승은 대결이 하나뿐이라 조를 나누지 않는다.
            if (!match.isFinal)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.resultHistoryGroup(match.groupLabel),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(child: _Participant(match, match.first)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l10n.resultHistoryVersus,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: _Participant(match, match.second)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Participant extends StatelessWidget {
  final MatchRecord match;
  final WorldCupItemModel item;

  const _Participant(this.match, this.item);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outcome = match.outcomeOf(item);
    final eliminated = outcome == MatchOutcome.eliminated;
    return MergeSemantics(
      child: Column(
        children: [
          MatchHistoryAvatar(
            item,
            size: _avatarSize,
            dimmed: eliminated,
            highlighted: outcome == MatchOutcome.champion,
          ),
          const SizedBox(height: 6),
          Text(
            matchHistoryItemName(AppLocalizations.of(context), item),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: eliminated
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          MatchOutcomeChip(outcome),
        ],
      ),
    );
  }
}
