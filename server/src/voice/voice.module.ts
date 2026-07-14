import { Module } from '@nestjs/common';
import { VoiceGateway } from './voice.gateway';
import { DeepgramService } from './deepgram.service';

@Module({
  providers: [VoiceGateway, DeepgramService],
  exports: [DeepgramService],
})
export class VoiceModule {}
