import { describe, it, expect } from '@ohos/hypium';
import {
  MORE_DESTINATION, NativeControlConfiguration, NativeDockConfiguration
} from '../../../main/ets/platform/native_ui/NativeUiModels';

function dockArguments(ids: string[], selected: string): Map<string, Object> {
  const items: Map<string, Object>[] = [];
  for (const id of ids) {
    const item = new Map<string, Object>();
    item.set('id', id);
    item.set('label', id);
    item.set('badge', id === 'sixth');
    item.set('badgeLabel', id === 'sixth' ? 'New items' : '');
    items.push(item);
  }
  const args = new Map<string, Object>();
  args.set('items', items);
  args.set('selectedId', selected);
  args.set('moreLabel', '更多');
  args.set('cancelLabel', '取消');
  return args;
}

export default function nativeUiTest() {
  describe('NativeUiConfiguration', () => {
    it('overflow keeps the selected destination visible and aggregates hidden badges', 0, () => {
      const args = dockArguments(['course', 'campus', 'profile', 'fourth', 'fifth', 'sixth'], 'fifth');
      const config = new NativeDockConfiguration(args, true);
      const visible = config.visibleItems();
      expect(visible.length).assertEqual(5);
      expect(visible[0].id).assertEqual('course');
      expect(visible[3].id).assertEqual('fifth');
      expect(visible[4].id).assertEqual(MORE_DESTINATION);
      expect(visible[4].badge).assertTrue();
      expect(visible[4].badgeLabel).assertEqual('New items');
      expect(config.selectedIndex()).assertEqual(3);
      expect(config.items.length).assertEqual(6);
      args.set('selectedId', 'sixth');
      const selectedBadge = new NativeDockConfiguration(args, true).visibleItems();
      expect(selectedBadge[3].badge).assertTrue();
      expect(selectedBadge[4].badge).assertFalse();
    });

    it('reordering uses stable IDs and ordinary docks retain their presentation', 0, () => {
      const config = new NativeDockConfiguration(dockArguments(['campus', 'course'], 'course'), false);
      expect(config.selectedIndex()).assertEqual(1);
      expect(config.visibleItems().length).assertEqual(2);
      expect(config.floating).assertFalse();
    });

    it('duplicate and missing selected IDs are rejected before replacing a view', 0, () => {
      let duplicatesRejected = false;
      let missingRejected = false;
      try {
        new NativeDockConfiguration(dockArguments(['course', 'course'], 'course'), true);
      } catch (_error) { duplicatesRejected = true; }
      try {
        new NativeDockConfiguration(dockArguments(['course', 'campus'], 'removed'), true);
      } catch (_error) { missingRejected = true; }
      expect(duplicatesRejected).assertTrue();
      expect(missingRejected).assertTrue();
    });

    it('loading disables activation and transmitted text scaling is bounded', 0, () => {
      const args = new Map<string, Object>();
      args.set('kind', 'button');
      args.set('enabled', true);
      args.set('loading', true);
      args.set('textScale', 10);
      const config = new NativeControlConfiguration(args);
      expect(config.enabled).assertFalse();
      expect(config.textScale).assertEqual(2);
    });
  });
}
