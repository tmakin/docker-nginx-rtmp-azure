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

		private var _serverUrl:String = "rtmp://localhost/test";
		
		

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
			
			addButton(0, "Record", clickListener);
			
			addButton(30, "Playback", playListener);
		}
		

		private function addButton(y:uint, text:String, listener: Function) {
			
			var btn:TextField = new TextField();
			btn.text = text;
			btn.y = y;
			btn.height = 20;
			btn.background = true;
			btn.addEventListener(MouseEvent.CLICK, listener);
			addChild(btn);	
		}
		

		private function clickListener(e:Event):void
		{
			_recorder.record("flash-test");
		}
		
		private function playListener(e:Event):void
		{
			_recorder.stopRecording();
			
			_recorder.play();
		}
	}

}