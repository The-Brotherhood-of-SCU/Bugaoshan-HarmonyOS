import deviceInfo from '@ohos.deviceInfo';
import { NativeAppearance, NativeDockConfiguration } from './NativeUiModels';
import lazy { NativeUiMaterialApi26 } from './NativeUiMaterialApi26';

// Keep API 26 calls in guarded modifiers: the application still installs on API 20.
export class NativeUiMaterial {
  static hasApi26(): boolean {
    return deviceInfo.sdkApiVersion >= 26;
  }

  static isEnabled(): boolean {
    if (!NativeUiMaterial.hasApi26()) return false;
    return NativeUiMaterialApi26.isEnabled();
  }
}

export class NativeSwitchAppearance implements AttributeModifier<ToggleAttribute> {
  private appearance: NativeAppearance;

  constructor(appearance: NativeAppearance) {
    this.appearance = appearance;
  }

  applyNormalAttribute(instance: ToggleAttribute): void {
    instance.selectedColor(this.appearance.accent());
    if (NativeUiMaterial.hasApi26()) {
      NativeUiMaterialApi26.applySwitch(instance, this.appearance);
    }
  }
}

export class NativeDockAppearance implements AttributeModifier<TabsAttribute> {
  private configuration: NativeDockConfiguration;

  constructor(configuration: NativeDockConfiguration) {
    this.configuration = configuration;
  }

  applyNormalAttribute(instance: TabsAttribute): void {
    if (NativeUiMaterial.hasApi26() && this.configuration.floating) {
      NativeUiMaterialApi26.applyDock(instance, this.configuration);
    } else {
      instance.barBackgroundColor(this.configuration.surface());
    }
  }
}
