<template>
  <video ref="videoPlayer" class="video-max" controls preload="auto">
    <source :src="source" />
    <track
      kind="subtitles"
      v-for="(sub, index) in subtitles"
      :key="index"
      :src="sub"
      :label="subLabel(sub)"
      :default="index === 0"
    />
    <p>
      Sorry, your browser doesn't support embedded videos, but don't worry, you
      can <a :href="source">download it</a>
      and watch it with your favorite video player!
    </p>
  </video>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue";

const videoPlayer = ref<HTMLVideoElement | null>(null);

const props = withDefaults(
  defineProps<{
    source: string;
    subtitles?: string[];
    options?: any;
  }>(),
  {
    options: {},
  }
);

onMounted(() => {
  if (videoPlayer.value && props.options?.autoplay) {
    videoPlayer.value.autoplay = true;
  }
});

const subLabel = (subUrl: string) => {
  let url: URL;
  try {
    url = new URL(subUrl);
  } catch {
    // treat it as a relative url
    // we only need this for filename
    url = new URL(subUrl, window.location.origin);
  }

  const label = decodeURIComponent(
    url.pathname
      .split("/")
      .pop()!
      .replace(/\.[^/.]+$/, "")
  );

  return label;
};
</script>

<style scoped>
.video-max {
  width: 100%;
  height: 100%;
}
</style>
