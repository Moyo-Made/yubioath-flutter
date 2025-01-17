/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/message.dart';
import '../../app/models.dart';
import '../../app/shortcuts.dart';
import '../../app/views/app_failure_page.dart';
import '../../app/views/app_list_item.dart';
import '../../app/views/app_page.dart';
import '../../app/views/message_page.dart';
import '../../core/state.dart';
import '../../widgets/list_title.dart';
import '../features.dart' as features;
import '../keys.dart';
import '../models.dart';
import '../state.dart';
import 'actions.dart';
import 'key_actions.dart';
import 'slot_dialog.dart';

class PivScreen extends ConsumerWidget {
  final DevicePath devicePath;

  const PivScreen(this.devicePath, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasFeature = ref.watch(featureProvider);
    return ref.watch(pivStateProvider(devicePath)).when(
          loading: () => MessagePage(
            title: Text(l10n.s_certificates),
            graphic: const CircularProgressIndicator(),
            delayedContent: true,
          ),
          error: (error, _) => AppFailurePage(
            title: Text(l10n.s_certificates),
            cause: error,
          ),
          data: (pivState) {
            final pivSlots = ref.watch(pivSlotsProvider(devicePath)).asData;
            return AppPage(
              title: Text(l10n.s_certificates),
              keyActionsBuilder: hasFeature(features.actions)
                  ? (context) =>
                      pivBuildActions(context, devicePath, pivState, ref)
                  : null,
              child: Column(
                children: [
                  ListTitle(l10n.s_certificates),
                  if (pivSlots?.hasValue == true)
                    ...pivSlots!.value.map((e) => registerPivActions(
                          devicePath,
                          pivState,
                          e,
                          ref: ref,
                          actions: {
                            OpenIntent:
                                CallbackAction<OpenIntent>(onInvoke: (_) async {
                              await showBlurDialog(
                                context: context,
                                barrierColor: Colors.transparent,
                                builder: (context) => SlotDialog(e.slot),
                              );
                              return null;
                            }),
                          },
                          builder: (context) => _CertificateListItem(e),
                        )),
                ],
              ),
            );
          },
        );
  }
}

class _CertificateListItem extends ConsumerWidget {
  final PivSlot pivSlot;

  const _CertificateListItem(this.pivSlot);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = pivSlot.slot;
    final certInfo = pivSlot.certInfo;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasFeature = ref.watch(featureProvider);

    return Semantics(
        label: slot.getDisplayName(l10n),
        child: AppListItem(
          key: _getAppListItemKey(slot),
          leading: CircleAvatar(
            foregroundColor: colorScheme.onSecondary,
            backgroundColor: colorScheme.secondary,
            child: const Icon(Icons.approval),
          ),
          title: slot.getDisplayName(l10n),
          subtitle: certInfo != null
              // Simplify subtitle by stripping "CN=", etc.
              ? certInfo.subject.replaceAll(RegExp(r'[A-Z]+='), ' ').trimLeft()
              : pivSlot.hasKey == true
                  ? l10n.l_key_no_certificate
                  : l10n.l_no_certificate,
          trailing: OutlinedButton(
            key: _getMeatballKey(slot),
            onPressed: Actions.handler(context, const OpenIntent()),
            child: const Icon(Icons.more_horiz),
          ),
          buildPopupActions: hasFeature(features.slots)
              ? (context) => buildSlotActions(certInfo != null, l10n)
              : null,
        ));
  }

  Key _getMeatballKey(SlotId slotId) => switch (slotId) {
        SlotId.authentication => meatballButton9a,
        SlotId.signature => meatballButton9c,
        SlotId.keyManagement => meatballButton9d,
        SlotId.cardAuth => meatballButton9e,
      };

  Key _getAppListItemKey(SlotId slotId) => switch (slotId) {
        SlotId.authentication => appListItem9a,
        SlotId.signature => appListItem9c,
        SlotId.keyManagement => appListItem9d,
        SlotId.cardAuth => appListItem9e
      };
}
