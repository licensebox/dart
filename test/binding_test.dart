import 'package:licensebox/licensebox.dart';
import 'dart:io';
void main(){if(!Client.deriveBinding('demo','linux-machine-id','12345678123456789abc1234567890ab\u0000').startsWith('m1:'))throw StateError('derive');try{Client.verifyLease('bad','demo',{},0);throw StateError('accepted');}on LicenseboxException catch(e){if(e.code!='malformed')rethrow;}final dir=Directory.systemTemp.createTempSync('licensebox-dart-');
final c=Client(product:'demo',keys:{'test-key':'A6EHv_POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg'},directory:dir.path,hooks:Hooks(machineBinding:()=>throw StateError('synthetic callback failure')));
try{try{c.signIn(timeout:.1);throw StateError('callback ignored');}on LicenseboxException catch(e){if(e.code!='callback_error')rethrow;}}finally{c.close();c.close();dir.deleteSync(recursive:true);}
print('Dart binding checks passed');}
