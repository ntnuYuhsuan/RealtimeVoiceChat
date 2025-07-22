# audio_module.py - 簡化版，僅支援STT功能
import asyncio
import logging
import threading
import time
from queue import Queue
from typing import Callable, Generator, Optional

logger = logging.getLogger(__name__)

class AudioProcessor:
    """
    簡化的音頻處理器，移除所有TTS功能以節省CUDA記憶體。
    現在這個類別主要作為佔位符，確保與現有代碼的兼容性。
    """
    
    def __init__(self) -> None:
        """
        初始化簡化的AudioProcessor。
        移除所有TTS引擎和相關依賴以避免CUDA記憶體問題。
        """
        logger.info("🎯 初始化簡化AudioProcessor (僅STT功能)")
        
        # 保持基本事件和隊列以維持兼容性
        self.stop_event = threading.Event()
        self.finished_event = threading.Event()
        self.audio_chunks = asyncio.Queue()
        
        # 移除TTS相關屬性
        # 設定虛擬的TTS推理時間以維持兼容性
        self.tts_inference_time = 0
        
        # 回調函數
        self.on_first_audio_chunk_synthesize: Optional[Callable[[], None]] = None
        
        logger.info("✅ AudioProcessor初始化完成 (TTS功能已禁用)")

    def on_audio_stream_stop(self) -> None:
        """
        音頻流停止的回調函數。
        """
        logger.info("🛑 音頻流已停止")
        self.finished_event.set()

    def synthesize(
            self,
            text: str,
            audio_chunks: Queue, 
            stop_event: threading.Event,
            generation_string: str = "",
        ) -> bool:
        """
        TTS合成功能已禁用。
        
        由於我們只需要STT功能，此方法現在會立即返回False。
        這確保了與現有代碼的兼容性，同時避免載入TTS模型。
        
        Args:
            text: 要合成的文字
            audio_chunks: 音頻塊隊列
            stop_event: 停止事件
            generation_string: 生成字符串標識
            
        Returns:
            False - 表示TTS功能已禁用
        """
        logger.info(f"⚠️ TTS功能已禁用 - 跳過文字合成: {text[:50]}...")
        return False

    def synthesize_generator(
            self,
            generator: Generator[str, None, None],
            audio_chunks: Queue,
            stop_event: threading.Event,
            generation_string: str = "",
        ) -> bool:
        """
        TTS生成器合成功能已禁用。
        
        由於我們只需要STT功能，此方法現在會立即返回False。
        
        Args:
            generator: 文字生成器
            audio_chunks: 音頻塊隊列
            stop_event: 停止事件
            generation_string: 生成字符串標識
            
        Returns:
            False - 表示TTS功能已禁用
        """
        logger.info(f"⚠️ TTS生成器功能已禁用 - 跳過生成器合成")
        return False