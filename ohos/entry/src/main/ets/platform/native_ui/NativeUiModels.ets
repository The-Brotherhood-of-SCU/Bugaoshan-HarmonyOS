// StandardMessageCodec decodes Dart maps as Map, not plain ArkTS objects.
export class NativeArguments {
  private values: Map<string, Object>;

  constructor(value: Object) {
    if (!(value instanceof Map)) throw new Error('Expected a configuration map');
    this.values = value as Map<string, Object>;
  }

  text(key: string, fallback: string = ''): string {
    const value = this.values.get(key);
    return typeof value === 'string' ? value : fallback;
  }

  flag(key: string, fallback: boolean = false): boolean {
    const value = this.values.get(key);
    return typeof value === 'boolean' ? value : fallback;
  }

  number(key: string, fallback: number, minimum: number, maximum: number): number {
    const value = this.values.get(key);
    return typeof value === 'number' && Number.isFinite(value) ?
      Math.max(minimum, Math.min(maximum, value)) : fallback;
  }

  list(key: string): Object[] {
    const value = this.values.get(key);
    if (!Array.isArray(value)) throw new Error(`Expected a list: ${key}`);
    return value as Object[];
  }
}

export class NativeAppearance {
  tint: number = 0xff006a60;
  dark: boolean = false;
  reduceMotion: boolean = false;
  highContrast: boolean = false;
  textScale: number = 1;
  rtl: boolean = false;

  constructor(args: NativeArguments) {
    this.tint = args.number('tint', this.tint, 0, 0xffffffff) >>> 0;
    this.dark = args.text('brightness') === 'dark';
    this.reduceMotion = args.flag('reduceMotion');
    this.highContrast = args.flag('highContrast');
    this.textScale = args.number('textScale', 1, 1, 2);
    this.rtl = args.text('direction') === 'rtl';
  }

  foreground(): number {
    return this.dark ? 0xfff1f3f5 : 0xff182431;
  }

  surface(): number {
    return this.dark ? 0xff202124 : 0xfff1f3f5;
  }

  accent(): number {
    return this.highContrast ? this.foreground() : this.tint;
  }
}

export class NativeControlConfiguration extends NativeAppearance {
  kind: string;
  label: string;
  symbol: string;
  value: boolean;
  enabled: boolean;
  loading: boolean;
  prominent: boolean;

  constructor(value: Object) {
    const args = new NativeArguments(value);
    super(args);
    this.kind = args.text('kind');
    if (this.kind !== 'button' && this.kind !== 'switch') throw new Error('Unknown control kind');
    this.label = args.text('label');
    this.symbol = args.text('symbol');
    this.value = args.flag('value');
    this.loading = args.flag('loading');
    this.enabled = args.flag('enabled') && !this.loading;
    this.prominent = args.text('style') === 'prominent';
  }
}

export const MORE_DESTINATION = '__native_more__';

export class NativeDockItem {
  id: string = '';
  label: string = '';
  badge: boolean = false;
  badgeLabel: string = '';

  // Rebuild a row when its plain configuration object changes. Events still use id.
  renderKey(): string {
    return JSON.stringify([this.id, this.label, this.badge ? '1' : '0', this.badgeLabel]);
  }
}

export class NativeDockConfiguration extends NativeAppearance {
  items: NativeDockItem[] = [];
  selectedId: string;
  moreLabel: string;
  cancelLabel: string;
  bottomInset: number;
  floating: boolean;

  constructor(value: Object, floating: boolean) {
    const args = new NativeArguments(value);
    super(args);
    this.floating = floating;
    this.selectedId = args.text('selectedId');
    this.moreLabel = args.text('moreLabel');
    this.cancelLabel = args.text('cancelLabel');
    this.bottomInset = args.number('bottomInset', 0, 0, 160);
    const entries = args.list('items');
    if (entries.length < 2 || entries.length > 64) throw new Error('Expected 2 to 64 destinations');
    const ids = new Set<string>();
    for (const entry of entries) {
      const itemArgs = new NativeArguments(entry);
      const item = new NativeDockItem();
      item.id = itemArgs.text('id');
      item.label = itemArgs.text('label');
      item.badge = itemArgs.flag('badge');
      item.badgeLabel = itemArgs.text('badgeLabel');
      if (item.id === '' || item.id === MORE_DESTINATION || ids.has(item.id)) {
        throw new Error('Destination IDs must be nonempty and unique');
      }
      ids.add(item.id);
      this.items.push(item);
    }
    if (!ids.has(this.selectedId)) throw new Error('Selected destination is absent');
  }

  visibleItems(): NativeDockItem[] {
    if (this.items.length <= 5) return this.items;
    const first = this.items.slice(0, 3);
    const selected = this.items.find((item: NativeDockItem) => item.id === this.selectedId);
    const fourth = first.some((item: NativeDockItem) => item.id === this.selectedId) ?
      this.items[3] : selected!;
    const visible = first.concat([fourth]);
    const more = new NativeDockItem();
    more.id = MORE_DESTINATION;
    more.label = this.moreLabel;
    const hiddenBadge = this.items.find((item: NativeDockItem) => item.badge &&
      !visible.some((shown: NativeDockItem) => shown.id === item.id));
    more.badge = hiddenBadge !== undefined;
    more.badgeLabel = hiddenBadge ? hiddenBadge.badgeLabel : '';
    return visible.concat([more]);
  }

  selectedIndex(): number {
    return this.visibleItems().findIndex((item: NativeDockItem) => item.id === this.selectedId);
  }
}
