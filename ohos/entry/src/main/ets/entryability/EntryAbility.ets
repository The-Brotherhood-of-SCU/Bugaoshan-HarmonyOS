import {
  FlutterAbility,
  FlutterEngine,
  MethodCall,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';
import Want from '@ohos.app.ability.Want';
import wantConstant from '@ohos.app.ability.wantConstant';
import fileuri from '@ohos.file.fileuri';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

const CHANNEL = 'bugaoshan/update';

export default class EntryAbility extends FlutterAbility {
  private methodChannel: MethodChannel | null = null;

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);

    this.methodChannel = new MethodChannel(flutterEngine.getDartExecutor(), CHANNEL);
    this.methodChannel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult): void => {
        if (call.method === 'importIcsToCalendar') {
          this.importIcsToCalendar(call.argument('path') as string, result);
        } else {
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

    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: fileuri.getUriFromPath(path),
      type: 'text/calendar',
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION,
      parameters: {
        mimeType: 'text/calendar'
      }
    };

    this.context.startAbility(want).then(() => {
      result.success('opened');
    }).catch((error: Error) => {
      result.error('OPEN_FAILED', error.message, null);
    });
  }
}
