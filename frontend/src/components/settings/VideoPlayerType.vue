<template>
  <select
    v-model="selectedVideoPlayerType"
    @change="emit('update:videoPlayerType', selectedVideoPlayerType)"
  >
    <option value="videojs">{{ t("settings.videoPlayerVideoJS") }}</option>
    <option value="simple">{{ t("settings.videoPlayerSimple") }}</option>
  </select>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import { useI18n } from "vue-i18n";

const { t } = useI18n();

const props = defineProps<{
  videoPlayerType: VideoPlayerType;
}>();

const emit = defineEmits<{
  (event: "update:videoPlayerType", value: VideoPlayerType): void;
}>();

const selectedVideoPlayerType = ref<VideoPlayerType>(props.videoPlayerType);

watch(
  () => props.videoPlayerType,
  (newValue) => {
    selectedVideoPlayerType.value = newValue;
  }
);
</script>
