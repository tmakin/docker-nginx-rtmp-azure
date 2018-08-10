//https://gist.github.com/Kalinovych/774b092d5230052b41d9
//https://stackoverflow.com/questions/6945055/flash-security-settings-panel-listening-for-close-event
package {
	
import flash.display.InteractiveObject;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.system.Security;
import flash.system.SecurityPanel;

public class SecurityPanelUtil {
	private static var _stage:Stage;
	private static var _observer:InteractiveObject;
	private static var _prevFocus:InteractiveObject;
	private static var _closeCallbacks:Vector.<Function>;

	private static var _isShown:Boolean = false;
	private static var _wasClosed:Boolean = false;

	/** Return true if the SecurityPanel dialog is visible on the stage right now */
	public static function get isShown():Boolean {
		return _isShown;
	}

	/** Return true if the SecurityPanel dialog was shown and then closed */
	public static function get wasClosed():Boolean {
		return _wasClosed;
	}

	/** True if observing of the SecurityPanel dialog behaviour in progress */
	public static function get isObserving():Boolean {
		return (_observer != null);
	}

	public static function show( panel:String, stage:Stage, closeCallback:Function ):void {
		_stage = stage;

		addCloseCallback( closeCallback );

		if ( isObserving ) return;

		setupObserver();

		_isShown = false;
		_wasClosed = false;

		Security.showSettings( panel );
	}

	public static function showPrivacySettings( stage:Stage, closeCallback:Function ):void {
		show( SecurityPanel.PRIVACY, stage, closeCallback );
	}

	//---------------------------------------------
	// Private
	//---------------------------------------------

	private static function onDialogShown():void {
		_isShown = true;
	}

	private static function onDialogClosed():void {
		_wasClosed = true;
		_isShown = false;
		_stage && (_stage.focus = _prevFocus);
		_prevFocus = null;
		_observer = null;
		_stage = null;
		executeCloseCallbacks();
	}

	private static function addCloseCallback( callback:Function ):void {
		if ( !_closeCallbacks ) {
			_closeCallbacks = new <Function>[callback];
			return;
		}

		if ( _closeCallbacks.indexOf( callback ) >= 0 ) {
			return;
		}

		_closeCallbacks[_closeCallbacks.length] = callback;
	}

	private static function executeCloseCallbacks():void {
		const callbackCount:uint = _closeCallbacks ? _closeCallbacks.length : 0;
		if ( callbackCount == 0 ) return;

		for ( var i:uint = 0; i < callbackCount; i++ ) {
			_closeCallbacks[i]();
		}

		_closeCallbacks = null;
	}

	private static function setupObserver():void {
		_observer ||= new Sprite();

		_prevFocus = _stage.focus;
		_stage.focus = _observer;

		_observer.addEventListener( FocusEvent.FOCUS_OUT, handleFocusEvent );
		_observer.addEventListener( FocusEvent.FOCUS_IN, handleFocusEvent );
	}

	private static function handleFocusEvent( event:Event ):void {
		_observer.removeEventListener( event.type, handleFocusEvent );
		const shown:Boolean = (event.type == FocusEvent.FOCUS_OUT);
		shown ? onDialogShown() : onDialogClosed();
	}

}
}