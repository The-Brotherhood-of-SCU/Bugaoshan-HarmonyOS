import { BinaryMessenger } from '@ohos/flutter_ohos';
import { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { MORE_DESTINATION, NativeDockConfiguration, NativeDockItem } from './NativeUiModels';
import { NativeDockAppearance, NativeUiMaterial } from './NativeUiMaterial';
import { nativeDockIcon } from './NativeUiIcons';
import { NativeUiView } from './NativeUiView';

@Observed
export class NativeDockState {
  configuration: NativeDockConfiguration;
  moreVisible: boolean = false;

  constructor(configuration: NativeDockConfiguration) {
    this.configuration = configuration;
  }
}

export class NativeDockView extends NativeUiView {
  state: NativeDockState;

  constructor(messenger: BinaryMessenger, viewId: number, configuration: NativeDockConfiguration,
    onDispose: (view: NativeUiView) => void) {
    super(messenger, 'bugaoshan/liquid_glass_dock', viewId, onDispose);
    this.state = new NativeDockState(configuration);
  }

  protected update(value: Object): void {
    const next = new NativeDockConfiguration(value, NativeUiMaterial.hasApi26());
    this.state.configuration = next;
    if (next.items.length <= 5) this.state.moreVisible = false;
  }

  select(id: string): void {
    const config = this.state.configuration;
    if (!this.disposed && id !== config.selectedId &&
      config.items.some((item: NativeDockItem) => item.id === id)) this.emit('select', id);
  }

  openMore(): void {
    if (!this.disposed) this.state.moreVisible = true;
  }

  protected releaseView(): void {
    this.state.moreVisible = false;
  }

  getView(): WrappedBuilder<[Params]> {
    return new WrappedBuilder(NativeDockBuilder);
  }
}

@Builder
function NativeDockBuilder(params: Params) {
  NativeDockComponent({
    state: (params.platformView as NativeDockView).state,
    view: params.platformView as NativeDockView
  })
}

@Component
struct NativeDockComponent {
  @ObjectLink state: NativeDockState;
  view: NativeDockView;

  private selected(item: NativeDockItem): boolean {
    return item.id === this.state.configuration.selectedId;
  }

  private itemColor(item: NativeDockItem): number {
    if (this.selected(item)) return this.state.configuration.accent();
    if (this.state.configuration.highContrast) return this.state.configuration.foreground();
    return this.state.configuration.dark ? 0xffbfc5cc : 0xff56606b;
  }

  @Builder
  icon(item: NativeDockItem, size: number, color: number) {
    Stack({ alignContent: Alignment.TopEnd }) {
      SymbolGlyph(nativeDockIcon(item.id, this.selected(item))).fontSize(size).fontColor([color])
        .accessibilityLevel('no')
      if (item.badge) {
        Circle().width(7).height(7).fill(this.state.configuration.accent())
          .accessibilityLevel('no')
      }
    }.width(size).height(size)
  }

  @Builder
  tab(item: NativeDockItem) {
    Column({ space: 3 }) {
      this.icon(item, 24, this.itemColor(item))
      Text(item.label).fontSize(`${10 * this.state.configuration.textScale}vp`)
        .fontWeight(this.selected(item) ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.itemColor(item)).maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%').height('100%').padding({ top: 6, bottom: 6, left: 4, right: 4 })
    .justifyContent(FlexAlign.Center)
    .accessibilityGroup(true).accessibilityText(item.label)
    .accessibilityDescription(item.badge ? item.badgeLabel : '')
    .accessibilitySelected(this.selected(item))
  }

  @Builder
  moreContent() {
    WithTheme({ colorMode: this.state.configuration.dark ? ThemeColorMode.DARK : ThemeColorMode.LIGHT }) {
      Column({ space: 12 }) {
        Row() {
          Text(this.state.configuration.moreLabel)
            .fontSize(`${20 * this.state.configuration.textScale}vp`)
            .fontWeight(FontWeight.Medium).fontColor(this.state.configuration.foreground())
            .layoutWeight(1)
          Button(this.state.configuration.cancelLabel)
            .fontSize(`${16 * this.state.configuration.textScale}vp`)
            .fontColor(this.state.configuration.accent())
            .backgroundColor(Color.Transparent)
            .onClick(() => this.state.moreVisible = false)
        }.width('100%')
        List({ space: 4 }) {
          ForEach(this.state.configuration.items, (item: NativeDockItem) => {
            ListItem() {
              Button({ type: ButtonType.Normal, stateEffect: !this.state.configuration.reduceMotion }) {
                Row({ space: 16 }) {
                  this.icon(item, 24, this.state.configuration.accent())
                  Text(item.label).layoutWeight(1).textAlign(TextAlign.Start)
                    .fontSize(`${16 * this.state.configuration.textScale}vp`)
                    .fontColor(this.state.configuration.foreground())
                    .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  if (this.selected(item)) {
                    SymbolGlyph($r('sys.symbol.checkmark')).fontSize(20)
                      .fontColor([this.state.configuration.accent()]).accessibilityLevel('no')
                  }
                }.width('100%').padding(12)
              }
              .width('100%').backgroundColor(Color.Transparent).borderRadius(12)
              .accessibilityText(item.label)
              .accessibilityDescription(item.badge ? item.badgeLabel : '')
              .accessibilitySelected(this.selected(item))
              .onClick(() => {
                this.state.moreVisible = false;
                this.view.select(item.id);
              })
            }
          }, (item: NativeDockItem) => item.renderKey())
        }.layoutWeight(1).width('100%')
      }
      .width('100%').height('100%').padding(16)
      .backgroundColor(this.state.configuration.surface())
      .direction(this.state.configuration.rtl ? Direction.Rtl : Direction.Ltr)
    }
  }

  build() {
    WithTheme({ colorMode: this.state.configuration.dark ? ThemeColorMode.DARK : ThemeColorMode.LIGHT }) {
      Tabs({ index: this.state.configuration.selectedIndex(), barPosition: BarPosition.End }) {
        ForEach(this.state.configuration.visibleItems(), (item: NativeDockItem) => {
          // The tab content is transparent: Flutter owns the actual pages.
          TabContent() { Column() {}.width('100%').height('100%') }
            .tabBar(this.tab(item))
        }, (item: NativeDockItem) => item.renderKey())
      }
      .width('100%').height('100%').vertical(false).barMode(BarMode.Fixed)
      .barHeight(64).scrollable(false).animationDuration(0)
      .barOverlap(this.state.configuration.floating)
      // Flutter supplies the full bottom inset; disable Tabs' implicit expansion.
      .expandSafeArea([], [])
      .padding({ bottom: this.state.configuration.floating ? 0 : this.state.configuration.bottomInset })
      .backgroundColor(this.state.configuration.floating ? Color.Transparent : this.state.configuration.surface())
      .direction(this.state.configuration.rtl ? Direction.Rtl : Direction.Ltr)
      .attributeModifier(new NativeDockAppearance(this.state.configuration))
      .onTabBarClick((index: number) => {
        if (this.state.configuration.visibleItems()[index]?.id === MORE_DESTINATION) this.view.openMore();
      })
      .onContentWillChange((_from: number, to: number): boolean => {
        const item = this.state.configuration.visibleItems()[to];
        if (!item) return false;
        // Programmatic updates may select Flutter's current ID without emitting.
        if (item.id === this.state.configuration.selectedId) return true;
        if (item.id === MORE_DESTINATION) this.view.openMore();
        else this.view.select(item.id);
        return false; // Wait for Flutter's authoritative selectedId.
      })
      .bindSheet($$this.state.moreVisible, this.moreContent, {
        height: SheetSize.MEDIUM,
        showClose: false,
        backgroundColor: this.state.configuration.surface()
      })
    }
  }
}
