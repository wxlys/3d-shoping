<template>
  <view class="print-page">
    <view class="hero">
      <view class="hero-title">定制打印询价</view>
      <view class="hero-desc">上传模型文件，选择规格后提交，报价将在后台审核后发送给你</view>
    </view>

    <view class="section">
      <view class="section-title">1. 模型文件</view>
      <view class="upload-box" @click="chooseFile">
        <view class="upload-icon">＋</view>
        <view>{{ selectedFile ? '重新上传模型文件' : '点击上传模型文件' }}</view>
        <view class="upload-tip">支持 STL、OBJ、3MF、STP、STEP，单文件不超过 {{ maxFileMb }}MB</view>
      </view>
      <view v-if="selectedFile" class="file-card">
        <view class="file-name">{{ selectedFile.filename }}</view>
        <view class="file-size">{{ selectedFile.size_text || formatSize(selectedFile.size) }}</view>
      </view>
      <view v-if="files.length" class="saved-files">
        <view class="saved-title">已上传文件（点击可选择）</view>
        <view v-for="item in files" :key="item.id" class="saved-file" :class="{ active: selectedFile && selectedFile.id === item.id }" @click.stop="selectFile(item)">
          <text>{{ item.filename }}</text>
          <text>{{ item.size_text }}</text>
        </view>
      </view>
    </view>

    <view class="section">
      <view class="section-title">2. 打印规格</view>
      <view class="form-row">
        <view class="form-label">尺寸档位</view>
        <view class="option-list">
          <view v-for="item in sizeOptions" :key="item.value" class="option" :class="{ selected: sizeLevel === item.value }" @click="sizeLevel = item.value">
            {{ item.label }}
          </view>
        </view>
      </view>
      <view class="form-row">
        <view class="form-label">打印材料</view>
        <view class="option-list">
          <view v-for="item in materialOptions" :key="item" class="option" :class="{ selected: material === item }" @click="material = item">
            {{ item }}
          </view>
        </view>
      </view>
      <view class="form-row quantity-row">
        <view class="form-label">打印数量</view>
        <view class="quantity-control">
          <view class="quantity-btn" @click="changeQuantity(-1)">−</view>
          <text>{{ quantity }}</text>
          <view class="quantity-btn" @click="changeQuantity(1)">＋</view>
        </view>
      </view>
    </view>

    <view class="notice">提交后由工作人员核算材料、工时和后处理费用。报价有效期为48小时，确认报价后会生成待支付订单。</view>

    <view class="footer">
      <button class="list-btn" @click="goList">我的询价</button>
      <button class="submit-btn" :disabled="submitting || uploading" @click="submitInquiry">{{ submitting ? '提交中...' : '提交询价' }}</button>
    </view>
  </view>
</template>

<script>
import { HTTP_REQUEST_URL, TOKENNAME } from '@/config/app.js';
import { createPrintInquiry, getPrintFileList } from '@/api/print3d.js';

export default {
  data() {
    return {
      productId: 0,
      requestedFileId: 0,
      uploading: false,
      submitting: false,
      files: [],
      selectedFile: null,
      sizeLevel: 'S',
      material: 'PLA',
      quantity: 1,
      maxFileMb: 100,
      sizeOptions: [
        { value: 'S', label: 'S 小型' },
        { value: 'M', label: 'M 中型' },
        { value: 'L', label: 'L 大型' },
        { value: 'XL', label: 'XL 超大型' },
      ],
      materialOptions: ['PLA', 'PETG'],
    };
  },
  onLoad(options) {
    this.productId = Number(options.product_id || 0);
    this.requestedFileId = Number(options.file_id || 0);
    this.loadFiles();
  },
  methods: {
    loadFiles() {
      getPrintFileList({ page: 1, limit: 20 })
        .then((res) => {
          this.files = (res.data && res.data.list) || [];
          if (this.requestedFileId) {
            this.selectedFile = this.files.find((item) => item.id === this.requestedFileId && item.status === 2) || null;
            if (!this.selectedFile) this.$util.Tips({ title: '该文件暂不可用于询价' });
          }
        })
        .catch(() => {});
    },
    chooseFile() {
      if (!this.$store.state.app.token) {
        this.$util.Tips({ title: '请先登录' });
        return;
      }
      // #ifdef MP-WEIXIN
      uni.chooseMessageFile({
        count: 1,
        type: 'file',
        success: (res) => this.uploadSelectedFile(res.tempFiles && res.tempFiles[0]),
      });
      // #endif
      // #ifndef MP-WEIXIN
      uni.chooseFile({
        count: 1,
        extension: ['stl', 'obj', '3mf', 'stp', 'step'],
        success: (res) => {
          const file = (res.tempFiles && res.tempFiles[0]) || { path: res.tempFilePaths && res.tempFilePaths[0] };
          this.uploadSelectedFile(file);
        },
      });
      // #endif
    },
    uploadSelectedFile(file) {
      if (!file || !(file.path || file.tempFilePath)) {
        this.$util.Tips({ title: '未选择文件' });
        return;
      }
      this.uploading = true;
      uni.uploadFile({
        url: `${HTTP_REQUEST_URL}/api/print/file/upload`,
        filePath: file.path || file.tempFilePath,
        name: 'file',
        header: {
          [TOKENNAME]: `Bearer ${this.$store.state.app.token}`,
        },
        success: (res) => {
          let data = res.data;
          if (typeof data === 'string') {
            try {
              data = JSON.parse(data);
            } catch (e) {
              data = {};
            }
          }
          if (data.status === 200 && data.data) {
            this.selectedFile = data.data;
            this.files = [data.data, ...this.files.filter((item) => item.id !== data.data.id)];
            uni.showToast({ title: '上传成功', icon: 'success' });
          } else {
            this.$util.Tips({ title: data.msg || '模型文件上传失败' });
          }
        },
        fail: () => this.$util.Tips({ title: '模型文件上传失败' }),
        complete: () => {
          this.uploading = false;
        },
      });
    },
    selectFile(file) {
      this.selectedFile = file;
    },
    changeQuantity(step) {
      this.quantity = Math.min(100, Math.max(1, this.quantity + step));
    },
    submitInquiry() {
      if (!this.selectedFile || !this.selectedFile.id) {
        this.$util.Tips({ title: '请先上传并选择模型文件' });
        return;
      }
      this.submitting = true;
      createPrintInquiry({
        file_id: this.selectedFile.id,
        size_level: this.sizeLevel,
        material: this.material,
        quantity: this.quantity,
      })
        .then(() => {
          uni.showToast({ title: '询价已提交', icon: 'success' });
          setTimeout(() => this.goList(), 500);
        })
        .catch((err) => this.$util.Tips({ title: typeof err === 'string' ? err : (err.msg || '提交失败') }))
        .finally(() => {
          this.submitting = false;
        });
    },
    goList() {
      uni.navigateTo({ url: '/pages/print/inquiry_list/index' });
    },
    formatSize(size) {
      if (size >= 1024 * 1024) return `${(size / 1024 / 1024).toFixed(2)} MB`;
      if (size >= 1024) return `${(size / 1024).toFixed(2)} KB`;
      return `${size || 0} B`;
    },
  },
};
</script>

<style lang="scss" scoped>
.print-page {
  min-height: 100vh;
  padding-bottom: 150rpx;
  background: #f7f8fa;
  color: #333;
}

.hero {
  padding: 44rpx 32rpx 38rpx;
  color: #fff;
  background: linear-gradient(135deg, #3875ea, #6d9cff);
}

.hero-title { font-size: 40rpx; font-weight: 600; }
.hero-desc { margin-top: 14rpx; font-size: 24rpx; opacity: .9; line-height: 1.6; }

.section {
  margin: 24rpx;
  padding: 28rpx;
  border-radius: 16rpx;
  background: #fff;
}

.section-title { font-size: 30rpx; font-weight: 600; margin-bottom: 24rpx; }
.upload-box { padding: 38rpx 20rpx; border: 2rpx dashed #c9d8f9; border-radius: 14rpx; text-align: center; color: #3875ea; background: #f7faff; }
.upload-icon { font-size: 54rpx; line-height: 54rpx; }
.upload-tip { margin-top: 10rpx; color: #999; font-size: 22rpx; }
.file-card { display: flex; justify-content: space-between; margin-top: 18rpx; padding: 18rpx; border-radius: 10rpx; background: #f0f6ff; font-size: 25rpx; }
.file-name { max-width: 70%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: #3875ea; }
.file-size { color: #999; }
.saved-files { margin-top: 24rpx; }
.saved-title { margin-bottom: 12rpx; color: #999; font-size: 23rpx; }
.saved-file { display: flex; justify-content: space-between; padding: 16rpx 0; color: #666; font-size: 24rpx; border-bottom: 1rpx solid #f1f1f1; }
.saved-file text:first-child { max-width: 70%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.saved-file.active { color: #3875ea; }
.form-row { display: flex; align-items: center; padding: 20rpx 0; border-bottom: 1rpx solid #f3f3f3; }
.form-label { width: 150rpx; color: #666; font-size: 26rpx; }
.option-list { display: flex; flex-wrap: wrap; gap: 16rpx; }
.option { padding: 12rpx 24rpx; border: 1rpx solid #ddd; border-radius: 40rpx; color: #666; font-size: 24rpx; }
.option.selected { color: #3875ea; border-color: #3875ea; background: #f0f6ff; }
.quantity-row { justify-content: space-between; border-bottom: 0; }
.quantity-control { display: flex; align-items: center; gap: 24rpx; }
.quantity-btn { width: 52rpx; height: 52rpx; border-radius: 50%; text-align: center; line-height: 50rpx; color: #3875ea; background: #f0f6ff; font-size: 34rpx; }
.notice { margin: 0 32rpx; color: #999; font-size: 23rpx; line-height: 1.7; }
.footer { position: fixed; right: 0; bottom: 0; left: 0; display: flex; gap: 20rpx; padding: 20rpx 28rpx calc(20rpx + env(safe-area-inset-bottom)); background: #fff; box-shadow: 0 -4rpx 16rpx rgba(0, 0, 0, .06); }
.footer button { flex: 1; height: 82rpx; margin: 0; border-radius: 42rpx; line-height: 82rpx; font-size: 28rpx; }
.list-btn { color: #3875ea; background: #f0f6ff; }
.submit-btn { color: #fff; background: #3875ea; }
.submit-btn[disabled] { opacity: .6; }
</style>
