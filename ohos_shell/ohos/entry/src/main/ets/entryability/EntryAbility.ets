import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import MethodChannel, { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import Want from '@ohos.app.ability.Want';
import wantConstant from '@ohos.app.ability.wantConstant';
import fileuri from '@ohos.file.fileuri';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

const CHANNEL = 'bugaoshan/update';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    this.configureBugaoshanChannel(flutterEngine)
  }

  private configureBugaoshanChannel(flutterEngine: FlutterEngine): void {
    const messenger = flutterEngine.getDartExecutor().getBinaryMessenger();
    const channel = new MethodChannel(messenger, CHANNEL);
    channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult) => {
        switch (call.method) {
          case 'importIcsToCalendar':
            this.importIcsToCalendar(call.argument('path') as string, result);
            break;
          case 'updateWidget':
            result.success(null);
            break;
          case 'installApk':
          case 'installHap':
            this.openInstallFile(call.argument('path') as string, result);
            break;
          default:
            result.notImplemented();
        }
      }
    });
  }

  private importIcsToCalendar(path: string, result: MethodResult): void {
    if (!path) {
      result.error('INVALID_ARGUMENT', 'Path is empty', null);
      return;
    }

    const uri = fileuri.getUriFromPath(path);
    const want: Want = {
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION | wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION,
      action: 'ohos.want.action.viewData',
      uri: uri,
      type: 'text/calendar',
      parameters: {
        mimeType: 'text/calendar'
      }
    };

    this.context.startAbility(want).then(() => {
      result.success('opened');
    }).catch((err: ESObject) => {
      result.error('OPEN_FAILED', err?.message ?? JSON.stringify(err), null);
    });
  }

  private openInstallFile(path: string, result: MethodResult): void {
    if (!path) {
      result.error('INVALID_ARGUMENT', 'Path is empty', null);
      return;
    }

    const uri = fileuri.getUriFromPath(path);
    const want: Want = {
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION,
      action: 'ohos.want.action.viewData',
      uri: uri,
      type: 'application/octet-stream',
      parameters: {
        mimeType: 'application/octet-stream'
      }
    };

    this.context.startAbility(want).then(() => {
      result.success(null);
    }).catch((err: ESObject) => {
      result.error('OPEN_FAILED', err?.message ?? JSON.stringify(err), null);
    });
  }
}
