<template>
  <view class="files-page">
    <view class="hero">
      <view>
        <view class="title">我的文件</view>
        <view class="subtitle">已通过校验的模型可以直接复用询价</view>
      </view>
      <view class="upload-btn" @click="goCreate">上传新模型</view>
    </view>

    <view v-if="files.length" class="file-list">
      <view v-for="item in files" :key="item.id" class="file-card">
        <view class="file-icon">{{ (item.ext || '?').toUpperCase() }}</view>
        <view class="file-main">
          <view class="file-name">{{ item.filename }}</view>
          <view class="file-meta">{{ item.size_text }} · {{ item.add_time_text }}</view>
          <view class="file-status" :class="`status-${item.status}`">{{ item.status_name }}</view>
        </view>
        <view class="file-actions">
          <view v-if="item.status === 2" class="reuse-btn" @click="reuse(item)">用于询价</view>
          <view v-if="!item.in_use" class="delete-btn" @click="remove(item)">删除</view>
        </view>
      </view>
    </view>
    <view v-else-if="!loading" class="empty">
      <view class="empty-title">还没有模型文件</view>
      <view class="empty-desc">上传模型后，可在后续询价中重复使用</view>
      <view class="empty-btn" @click="goCreate">上传并询价</view>
    </view>
  </view>
</template>

<script>
import { deletePrintFile, getPrintFileList } from '@/api/print3d.js';

export default {
  data() {
    return { files: [], loading: false };
  },
  onShow() {
    this.loadFiles();
  },
  methods: {
    loadFiles() {
      this.loading = true;
      getPrintFileList({ page: 1, limit: 100 })
        .then((res) => {
          this.files = (res.data && res.data.list) || [];
        })
        .catch((err) => this.$util.Tips({ title: typeof err === 'string' ? err : (err.msg || '加载失败') }))
        .finally(() => { this.loading = false; });
    },
    reuse(item) {
      uni.navigateTo({ url: `/pages/print/inquiry/index?file_id=${item.id}` });
    },
    remove(item) {
      uni.showModal({
        title: '删除模型',
        content: `确定删除“${item.filename}”吗？`,
        success: (res) => {
          if (!res.confirm) return;
          deletePrintFile(item.id)
            .then(() => {
              uni.showToast({ title: '已删除', icon: 'success' });
              this.loadFiles();
            })
            .catch((err) => this.$util.Tips({ title: typeof err === 'string' ? err : (err.msg || '删除失败') }));
        },
      });
    },
    goCreate() {
      uni.navigateTo({ url: '/pages/print/inquiry/index' });
    },
  },
};
</script>

<style lang="scss" scoped>
.files-page { min-height: 100vh; padding-bottom: 40rpx; background: #f7f8fa; color: #333; }
.hero { display: flex; align-items: center; justify-content: space-between; padding: 44rpx 32rpx 34rpx; color: #fff; background: linear-gradient(135deg, #3875ea, #6d9cff); }
.title { font-size: 40rpx; font-weight: 600; }
.subtitle { margin-top: 10rpx; font-size: 23rpx; opacity: .9; }
.upload-btn { padding: 14rpx 22rpx; border: 1rpx solid rgba(255,255,255,.75); border-radius: 36rpx; font-size: 24rpx; }
.file-list { padding-top: 1rpx; }
.file-card { display: flex; align-items: center; gap: 20rpx; margin: 24rpx; padding: 26rpx; border-radius: 16rpx; background: #fff; box-shadow: 0 4rpx 18rpx rgba(40,72,120,.04); }
.file-icon { flex: none; width: 82rpx; height: 82rpx; border-radius: 14rpx; color: #3875ea; background: #eef4ff; text-align: center; line-height: 82rpx; font-size: 22rpx; font-weight: 600; }
.file-main { flex: 1; min-width: 0; }
.file-name { overflow: hidden; color: #333; font-size: 28rpx; font-weight: 600; text-overflow: ellipsis; white-space: nowrap; }
.file-meta { margin-top: 10rpx; color: #999; font-size: 21rpx; }
.file-status { display: inline-block; margin-top: 10rpx; padding: 5rpx 12rpx; border-radius: 20rpx; color: #e6a23c; background: #fff7e8; font-size: 20rpx; }
.file-status.status-2 { color: #19a15f; background: #edfff5; }
.file-status.status-3 { color: #e93323; background: #fff1f0; }
.reuse-btn { flex: none; padding: 12rpx 18rpx; border-radius: 28rpx; color: #fff; background: #3875ea; font-size: 23rpx; }
.file-actions { display: flex; flex-direction: column; align-items: center; gap: 12rpx; }
.delete-btn { color: #999; font-size: 22rpx; }
.empty { padding-top: 180rpx; text-align: center; color: #999; }
.empty-title { color: #555; font-size: 32rpx; }
.empty-desc { margin-top: 16rpx; font-size: 24rpx; }
.empty-btn { display: inline-block; margin-top: 42rpx; padding: 20rpx 42rpx; border-radius: 40rpx; color: #fff; background: #3875ea; font-size: 26rpx; }
</style>
