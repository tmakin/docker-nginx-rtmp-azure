package
{
	import flash.net.*;
	import flash.events.*;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.media.Video;
	import flash.media.Microphone;
	import flash.media.Camera;
	import flash.media.SoundCodec;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author Tom Makin
	 */
	public class Main extends Sprite
	{
		private var _serverUrl:String = "rtmp://localhost/stream";
		
		private var _recorder: WebcamRecorder;
		
		public function Main()
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			
			_recorder = new WebcamRecorder(stage, _serverUrl);
			initCanvas();
			
			trace("init complete");
		}
		
		private function initCanvas():void {
			
			var connectButton:TextField = new TextField();
			connectButton.text = "Connect";
			connectButton.addEventListener(MouseEvent.CLICK,clickListener);
			addChild(connectButton);		
		}
		
		private function clickListener(e:Event):void
		{
			_recorder.record("test-client");
		}
	}

}