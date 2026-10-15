import common from '@ohos.app.ability.common';
import {
  BinaryMessenger, FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel,
  MethodResult, PlatformView, PlatformViewFactory, StandardMessageCodec
} from '@ohos/flutter_ohos';
import { NativeControlConfiguration, NativeDockConfiguration } from './NativeUiModels';
import { NativeControlView } from './NativeControlView';
import { NativeDockView } from './NativeDockView';
import { NativeUiMaterial } from './NativeUiMaterial';
import { NativeUiView } from './NativeUiView';

class NativeUiFactory extends PlatformViewFactory {
  private messenger: BinaryMessenger;
  private dock: boolean;
  private views: Set<NativeUiView>;

  constructor(messenger: BinaryMessenger, dock: boolean, views: Set<NativeUiView>) {
    super(StandardMessageCodec.INSTANCE);
    this.messenger = messenger;
    this.dock = dock;
    this.views = views;
  }

  create(_context: common.Context, viewId: number, args: Object): PlatformView {
    const remove = (view: NativeUiView): void => { this.views.delete(view); };
    const view: NativeUiView = this.dock ?
      new NativeDockView(this.messenger, viewId,
        new NativeDockConfiguration(args, NativeUiMaterial.hasApi26()), remove) :
      new NativeControlView(this.messenger, viewId, new NativeControlConfiguration(args), remove);
    this.views.add(view);
    return view;
  }
}

export class NativeUiPlugin implements FlutterPlugin {
  static readonly NAME: string = 'BugaoshanNativeUiPlugin';
  private channel: MethodChannel | null = null;
  private views: Set<NativeUiView> = new Set();

  getUniqueClassName(): string { return NativeUiPlugin.NAME; }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    const messenger = binding.getBinaryMessenger();
    const registry = binding.getPlatformViewRegistry();
    const dock = registry.registerViewFactory('bugaoshan/liquid_glass_dock',
      new NativeUiFactory(messenger, true, this.views));
    const controls = registry.registerViewFactory('bugaoshan/liquid_glass_control',
      new NativeUiFactory(messenger, false, this.views));
    this.channel = new MethodChannel(messenger, 'bugaoshan/liquid_glass');
    this.channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult): void => {
        if (call.method === 'isSupported') {
          result.success(dock && controls);
        } else if (call.method === 'getCapabilities') {
          const floating = dock && NativeUiMaterial.hasApi26();
          const immersive = NativeUiMaterial.isEnabled();
          const capabilities = new Map<string, Object>();
          capabilities.set('version', 1);
          capabilities.set('backend', 'ohos');
          capabilities.set('dock', dock);
          capabilities.set('button', controls);
          capabilities.set('switch', controls);
          capabilities.set('floatingDock', floating);
          capabilities.set('immersiveDock', floating && immersive);
          capabilities.set('immersiveSwitch', controls && immersive);
          capabilities.set('dockHeight', floating ? 88 : 64);
          capabilities.set('switchWidth', 64);
          capabilities.set('switchHeight', 48);
          result.success(capabilities);
        } else {
          result.notImplemented();
        }
      }
    });
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    for (const view of this.views) view.dispose();
    this.views.clear();
  }
}
