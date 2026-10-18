library;
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final class LicenseboxException implements Exception {
  final String code, detail;
  const LicenseboxException(this.code, [this.detail = '']);
  @override String toString() => 'licensebox: $code $detail';
}
/// Trusted platform hooks. Never obtain machineBinding from end-user input.
final class Hooks {
  final double Function()? clock;
  final String Function()? machineBinding;
  final void Function(String url, String code)? onSignIn;
  final bool Function()? cancelled;
  const Hooks({this.clock,this.machineBinding,this.onSignIn,this.cancelled});
}
final class _Callbacks extends Struct {
  external Pointer<Void> context;
  external Pointer<NativeFunction<Void Function(Pointer<Void>,Pointer<Utf8>,Pointer<Utf8>)>> signIn;
  external Pointer<NativeFunction<Double Function(Pointer<Void>)>> clock;
  external Pointer<NativeFunction<Int32 Function(Pointer<Void>,Pointer<Char>,Size)>> binding;
  external Pointer<NativeFunction<Int32 Function(Pointer<Void>)>> cancelled;
}
final class _Native {
  static final lib=DynamicLibrary.open(Platform.environment['LICENSEBOX_LIBRARY'] ?? '${Platform.environment['LICENSEBOX_LIB_DIR'] ?? ''}${Platform.environment.containsKey('LICENSEBOX_LIB_DIR')?'/':''}liblicensebox.so');
  static final create=lib.lookupFunction<Int32 Function(Pointer<Utf8>,Pointer<_Callbacks>,Pointer<Pointer<Void>>),int Function(Pointer<Utf8>,Pointer<_Callbacks>,Pointer<Pointer<Void>>) >('lb_client_create_json');
  static final call=lib.lookupFunction<Int32 Function(Pointer<Void>,Pointer<Utf8>,Pointer<Utf8>,Pointer<Pointer<Utf8>>),int Function(Pointer<Void>,Pointer<Utf8>,Pointer<Utf8>,Pointer<Pointer<Utf8>>) >('lb_client_call_json');
  static final destroy=lib.lookupFunction<Void Function(Pointer<Void>),void Function(Pointer<Void>)>('lb_client_destroy');
  static final free=lib.lookupFunction<Void Function(Pointer<Void>),void Function(Pointer<Void>)>('lb_free');
  static final result=lib.lookupFunction<Pointer<Utf8> Function(Int32),Pointer<Utf8> Function(int)>('lb_result_code');
  static final errorCode=lib.lookupFunction<Pointer<Utf8> Function(Pointer<Void>),Pointer<Utf8> Function(Pointer<Void>)>('lb_error_code');
  static final errorMessage=lib.lookupFunction<Pointer<Utf8> Function(Pointer<Void>),Pointer<Utf8> Function(Pointer<Void>)>('lb_error_message');
  static final derive=lib.lookupFunction<Int32 Function(Pointer<Utf8>,Pointer<Utf8>,Pointer<Utf8>,Pointer<Char>,Size),int Function(Pointer<Utf8>,Pointer<Utf8>,Pointer<Utf8>,Pointer<Char>,int)>('lb_derive_binding');
  static final native=lib.lookupFunction<Int32 Function(Pointer<Utf8>,Pointer<Char>,Size),int Function(Pointer<Utf8>,Pointer<Char>,int)>('lb_native_binding');
  static final verify=lib.lookupFunction<Int32 Function(Pointer<Utf8>,Pointer<Utf8>,Pointer<Utf8>,Double,Pointer<Pointer<Utf8>>),int Function(Pointer<Utf8>,Pointer<Utf8>,Pointer<Utf8>,double,Pointer<Pointer<Utf8>>)>('lb_verify_lease_json');
}
String _arg(String s){if(s.contains('\u0000'))throw const LicenseboxException('invalid_argument');return s;}
String _keys(Map<String,String> keys){keys.forEach((k,v){_arg(k);_arg(v);});return jsonEncode(keys);}
LicenseboxException _error(int r,[Pointer<Void>? h]){
  var code=_Native.result(r).toDartString(),detail=code;
  if(h!=null && code!='invalid_argument'){final saved=_Native.errorCode(h).toDartString();if(saved!='ok')code=saved;detail=_Native.errorMessage(h).toDartString();}
  return LicenseboxException(code,detail);
}
Object? _output(Pointer<Utf8> p){if(p==nullptr)throw const LicenseboxException('protocol_error');try{return jsonDecode(p.toDartString());}finally{_Native.free(p.cast());}}
/// Synchronous native client. Always close in a finally block; hooks must not reenter.
final class Client {
  Pointer<Void> _handle=nullptr;
  final Pointer<_Callbacks> _callbacks=calloc<_Callbacks>();
  final List<void Function()> _release=[];
  Object? _failure;
  bool _busy=false,_closed=false;
  Client({required String product,required Map<String,String> keys,String version='',String? server,String? directory,String? caBundle,Hooks hooks=const Hooks()}){
    try {
    final options=<String,Object>{'product':_arg(product),'keys':jsonDecode(_keys(keys)),'version':_arg(version)};
    if(server!=null)options['server']=_arg(server);if(directory!=null)options['directory']=_arg(directory);if(caBundle!=null)options['ca_bundle']=_arg(caBundle);
    if(hooks.onSignIn!=null){final cb=NativeCallable<Void Function(Pointer<Void>,Pointer<Utf8>,Pointer<Utf8>)>.isolateLocal((Pointer<Void> ctx,Pointer<Utf8> u,Pointer<Utf8> c){try{hooks.onSignIn!(u.toDartString(),c.toDartString());}catch(e){_failure=e;}});_callbacks.ref.signIn=cb.nativeFunction;_release.add(cb.close);}
    if(hooks.clock!=null){final cb=NativeCallable<Double Function(Pointer<Void>)>.isolateLocal((Pointer<Void> ctx){try{final v=hooks.clock!();if(!v.isFinite)throw const LicenseboxException('invalid_argument');return v;}catch(e){_failure=e;return 0.0;}},exceptionalReturn:0.0);_callbacks.ref.clock=cb.nativeFunction;_release.add(cb.close);}
    if(hooks.machineBinding!=null){final cb=NativeCallable<Int32 Function(Pointer<Void>,Pointer<Char>,Size)>.isolateLocal((Pointer<Void> ctx,Pointer<Char> out,int n){try{final s=utf8.encode(_arg(hooks.machineBinding!()));if(s.length>=n)return 1;out.cast<Uint8>().asTypedList(s.length+1).setAll(0,[...s,0]);return 0;}catch(e){_failure=e;return 1;}},exceptionalReturn:1);_callbacks.ref.binding=cb.nativeFunction;_release.add(cb.close);}
    final cb=NativeCallable<Int32 Function(Pointer<Void>)>.isolateLocal((Pointer<Void> ctx){try{return _failure!=null || (hooks.cancelled?.call() ?? false)?1:0;}catch(e){_failure=e;return 1;}},exceptionalReturn:1);_callbacks.ref.cancelled=cb.nativeFunction;_release.add(cb.close);
    using((a){final out=a<Pointer<Void>>();final r=_Native.create(jsonEncode(options).toNativeUtf8(allocator:a),_callbacks,out);_handle=out.value;if(r!=0 || _failure!=null){final error=_failure==null?_error(r):const LicenseboxException('callback_error');close();throw error;}});
    } catch (_) {close();rethrow;}
  }
  void close(){if(_busy)throw const LicenseboxException('invalid_argument','callback reentry');if(_closed)return;_closed=true;if(_handle!=nullptr)_Native.destroy(_handle);_handle=nullptr;for(final f in _release){f();}_release.clear();calloc.free(_callbacks);}
  Object? _call(String operation,[Map<String,Object> args=const {}]){
    if(_closed || _busy)throw const LicenseboxException('invalid_argument','closed or reentered client');_busy=true;
    try{return using((a){final out=a<Pointer<Utf8>>();final r=_Native.call(_handle,operation.toNativeUtf8(allocator:a),jsonEncode(args).toNativeUtf8(allocator:a),out);if(r!=0 || _failure!=null){_Native.free(out.value.cast());if(_failure!=null){final detail=_failure.toString();_failure=null;throw LicenseboxException('callback_error',detail);}throw _error(r,_handle);}return _output(out.value);});}finally{_busy=false;}
  }
  Object? lease()=>_call('lease');
  Object? heartbeat(String module)=>_call('heartbeat',{'module':_arg(module)});
  Object? requireModule(String module)=>_call('require',{'module':_arg(module)});
  Object? status()=>_call('status');
  Object? signIn({double timeout=0}){if(!timeout.isFinite)throw const LicenseboxException('invalid_argument');return _call('sign_in',{'timeout':timeout});}
  void logout(){_call('logout');}
  Object? modules()=>_call('modules');
  Object? requests()=>_call('requests');
  Object? requestAccess(List<String> modules,{String note=''})=>_call('request',{'modules':modules.map(_arg).toList(),'note':_arg(note)});
  String accessLink()=>_call('access-link') as String;
  void record(String command,{required bool success,required double elapsed}){if(!elapsed.isFinite||elapsed<0)throw const LicenseboxException('invalid_argument');_call('record',{'command':_arg(command),'success':success,'elapsed':elapsed});}
  static String deriveBinding(String product,String source,String raw){raw=raw.replaceFirst(RegExp(r'\x00+$'),'');if(raw.contains('\u0000'))throw const LicenseboxException('identity_unavailable');return using((a){final out=a<Char>(128);final r=_Native.derive(_arg(product).toNativeUtf8(allocator:a),_arg(source).toNativeUtf8(allocator:a),raw.toNativeUtf8(allocator:a),out,128);if(r!=0)throw _error(r);return out.cast<Utf8>().toDartString();});}
  static String nativeBinding(String product)=>using((a){final out=a<Char>(128);final r=_Native.native(_arg(product).toNativeUtf8(allocator:a),out,128);if(r!=0)throw _error(r);return out.cast<Utf8>().toDartString();});
  static Object? verifyLease(String token,String product,Map<String,String> keys,double now){if(!now.isFinite)throw const LicenseboxException('invalid_argument');return using((a){final out=a<Pointer<Utf8>>();final r=_Native.verify(_arg(token).toNativeUtf8(allocator:a),_arg(product).toNativeUtf8(allocator:a),_keys(keys).toNativeUtf8(allocator:a),now,out);if(r!=0){_Native.free(out.value.cast());throw _error(r);}return _output(out.value);});}
}
