import 'package:worldcup_ui_kit/worldcup_ui_kit.dart';

import 'dart:io';

import 'package:flutter/material.dart';

import 'worldcup_select_dialog.dart';

import 'package:worldcup_domain/worldcup_domain.dart';

class WorldCupListItem extends StatelessWidget {
  final WorldCupModel worldCupModel;

  const WorldCupListItem(this.worldCupModel, {super.key});

  @override
  Widget build(BuildContext context) {
    const cardRadius = 20.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cacheWidth =
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .round();
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(cardRadius),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildThumbnail(cacheWidth),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                worldCupModel.idx < 0
                    ? AppLocalizations.of(context).worldCupSampleTitle(
                        AppLocalizations.of(
                          context,
                        ).worldCupTitle(worldCupModel.idx, worldCupModel.title),
                      )
                    : AppLocalizations.of(
                        context,
                      ).worldCupTitle(worldCupModel.idx, worldCupModel.title),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                semanticsLabel: AppLocalizations.of(context).listTitleSemantics,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).worldCupMaxRound(
                  TournamentRounds.defaultRound(worldCupModel.maxRound),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                semanticsLabel: AppLocalizations.of(context)
                    .listMaxRoundSemantics,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(int cacheWidth) {
    if (worldCupModel.titleImageSrc.isEmpty) {
      return Image.asset(
        'assets/images/free_character.png',
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
      );
    }
    if (worldCupModel.idx < 0) {
      return Image.asset(
        worldCupModel.titleImageSrc,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
      );
    }
    return Image.file(
      File(worldCupModel.titleImageSrc),
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
    );
  }
}

Future<void> showDialogBeforeGameStart(
  BuildContext context,
  WorldCupModel model,
  VoidCallback onChanged,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return WorldCupSelectDialog(model, onChanged: onChanged);
    },
  );
}
