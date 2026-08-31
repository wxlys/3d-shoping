<template>
  <view class="list-page">
    <view class="topbar">
      <view>
        <view class="title">我的询价</view>
        <view class="subtitle">报价确认后将生成待支付订单</view>
      </view>
      <view class="new-btn" @click="goCreate">新建询价</view>
    </view>

    <view v-if="list.length" class="inquiry-list">
      <view v-for="item in list" :key="item.id" class="inquiry-card">
        <view class="card-head">
          <text class="inquiry-no">{{ item.inquiry_no }}</text>
          <text class="status" :class="`status-${item.status}`">{{ item.status_name }}</text>
        </view>
        <view class="file-name">{{ item.file.filename || '模型文件' }}</view>
        <view class="meta">{{ item.size_level }} / {{ item.material }} · {{ item.quantity }} 件 · {{ item.add_time_text }}</view>
        <view v-if="item.status === 2" class="quote-row">
          <text>报价</text><text class="price">¥ {{ item.quote_amount }}</text>
        </view>
        <view v-if="item.status === 2 && item.expire_at_text" class="expire">有效期至 {{ item.expire_at_text }}</view>
        <view v-if="item.status === 3 && item.order.order_id" class="order-no">订单号：{{ item.order.order_id }}</view>
        <view class="actions">
          <view class="action ghost" @click="openDetail(item)">查看详情</view>
          <view v-if="item.status === 1" class="action ghost" @click="cancel(item)">取消询价</view>
          <view v-if="item.status === 2" class="action primary" @click="confirm(item)">确认报价并支付</view>
          <view v-if="item.status === 3 && item.order.order_id" class="action primary" @click="goOrder(item)">查看订单</view>
        </view>
      </view>
    </view>
    <view v-else class="empty">
      <view class="empty-title">还没有询价单</view>
      <view class="empty-desc">上传你的第一个模型，开始定制打印</view>
      <view class="empty-btn" @click="goCreate">立即提交询价</view>
    </view>
  </view>
</template>

<script>
import { cancelPrintInquiry, confirmPrintInquiry, getPrintInquiryDetail, getPrintInquiryList } from '@/api/print3d.js';

export default {
  data() {
    return {
      list: [],
      page: 1,
      loading: false,
    };
  },
  onShow() {
    this.loadList();
  },
  methods: {
    loadList() {
      this.loading = true;
      getPrintInquiryList({ page: 1, limit: 50 })
        .then((res) => {
          this.list = (res.data && res.data.list) || [];
        })
        .catch((err) => this.$util.Tips({ title: typeof err === 'string' ? err : (err.msg || '加载失败') }))
        .finally(() => {
          this.loading = false;
        });
    },
    goCreate() {
      uni.navigateTo({ url: '/pages/print/inquiry/index' });
    },
    openDetail(item) {
      getPrintInquiryDetail(item.id)
        .then((res) => {
          const data = res.data || {};
          uni.showModal({
            title: data.inquiry_no || '询价详情',
            content: `状态：${data.status_name}\n规格：${data.size_level} / ${data.material} × ${data.quantity}\n报价：${data.quote_amount > 0 ? `¥ ${data.quote_amount}` : '待报价'}`,
            showCancel: false,
          });
        })
        .catch((err) => this.$util.Tips({ title: typeof err === 'string' ? err : (err.msg || '详情加载失败') }));
    },
    cancel(item) {
      uni.showModal({
        title: '取消询价',
        content: '确定取消这张询价单吗？',
        success: (res) => {
          if (!res.confirm) return;
          cancelPrintInquiry(item.id)
            .then(() => {
              uni.showToast({ title: '已取消', icon: 'success' });
              this.loadList();
            })
            .catch((err) => this.$util.Tips({ title: typeof err === 'string' ? err : (err.msg || '取消失败') }));
        },
      });
    },
    confirm(item) {
      uni.showModal({
        title: '确认报价',
        content: `确认支付 ¥${item.quote_amount} 开始制作吗？`,
        success: (res) => {
          if (!res.confirm) return;
          confirmPrintInquiry(item.id)
            .then((result) => {
              const orderId = result.data && result.data.order_id;
              if (orderId) {
                uni.navigateTo({ url: `/pages/goods/cashier/index?order_id=${orderId}&from_type=order` });
              }
              this.loadList();
            })
            .catch((err) => this.$util.Tips({ title: typeof err === 'string' ? err : (err.msg || '确认失败') }));
        },
      });
    },
    goOrder(item) {
      uni.navigateTo({ url: `/pages/goods/order_details/index?order_id=${item.order.order_id}` });
    },
  },
};
</script>

<style lang="scss" scoped>
.list-page { min-height: 100vh; padding-bottom: 40rpx; background: #f7f8fa; color: #333; }
.topbar { display: flex; align-items: center; justify-content: space-between; padding: 44rpx 32rpx 34rpx; color: #fff; background: linear-gradient(135deg, #3875ea, #6d9cff); }
.title { font-size: 40rpx; font-weight: 600; }
.subtitle { margin-top: 10rpx; font-size: 23rpx; opacity: .9; }
.new-btn { padding: 14rpx 22rpx; border: 1rpx solid rgba(255,255,255,.75); border-radius: 36rpx; font-size: 24rpx; }
.inquiry-card { margin: 24rpx; padding: 28rpx; border-radius: 16rpx; background: #fff; box-shadow: 0 4rpx 18rpx rgba(40, 72, 120, .04); }
.card-head { display: flex; justify-content: space-between; align-items: center; }
.inquiry-no { color: #666; font-size: 24rpx; }
.status { padding: 8rpx 14rpx; border-radius: 24rpx; font-size: 22rpx; }
.status-1 { color: #e6a23c; background: #fff7e8; }
.status-2 { color: #3875ea; background: #eef4ff; }
.status-3 { color: #19a15f; background: #edfff5; }
.status-4, .status-5 { color: #999; background: #f3f3f3; }
.file-name { margin-top: 24rpx; font-size: 30rpx; font-weight: 600; }
.meta, .expire, .order-no { margin-top: 12rpx; color: #999; font-size: 23rpx; }
.quote-row { display: flex; justify-content: space-between; align-items: center; margin-top: 22rpx; padding-top: 22rpx; border-top: 1rpx solid #f2f2f2; color: #666; font-size: 25rpx; }
.price { color: #e93323; font-size: 34rpx; font-weight: 600; }
.actions { display: flex; justify-content: flex-end; gap: 16rpx; margin-top: 24rpx; }
.action { padding: 12rpx 20rpx; border-radius: 30rpx; font-size: 23rpx; }
.action.ghost { color: #666; border: 1rpx solid #ddd; }
.action.primary { color: #fff; background: #3875ea; }
.empty { padding-top: 180rpx; text-align: center; color: #999; }
.empty-title { color: #555; font-size: 32rpx; }
.empty-desc { margin-top: 16rpx; font-size: 24rpx; }
.empty-btn { display: inline-block; margin-top: 42rpx; padding: 20rpx 42rpx; border-radius: 40rpx; color: #fff; background: #3875ea; font-size: 26rpx; }
</style>
