<template>
	<view :style="colorStyle">
		<view class="payment-status" v-if="loading">
			<!--失败时： 用icon-iconfontguanbi fail替换icon-duihao2 bg-color-->
			<view class="iconfont icons icon-duihao2 bg-color" v-if="order_pay_info.paid || order_pay_info.pay_type == 'offline'"></view>
			<view class="iconfont icons icon-iconfontguanbi" v-else></view>
			<!-- 失败时：订单支付失败 -->
			<view class="status" v-if="order_pay_info.pay_type != 'offline'">
				{{ order_pay_info.paid ? $t(`订单支付成功`) : $t(payType ? `订单支付中` : `订单支付失败`) }}
			</view>
			<view class="status" v-else>{{ $t(`订单创建成功`) }}</view>
			<view class="wrapper">
				<view class="item acea-row row-between-wrapper">
					<view>{{ $t(`订单号`) }}</view>
					<view class="itemCom">{{ orderId }}</view>
				</view>
				<view class="item acea-row row-between-wrapper">
					<view>{{ $t(`下单时间`) }}</view>
					<view class="itemCom">{{ order_pay_info._add_time }}</view>
				</view>
				<view class="item acea-row row-between-wrapper">
					<view>{{ $t(`支付方式`) }}</view>
					<view class="itemCom">{{ order_pay_info._status && order_pay_info._status._payType ? $t(order_pay_info._status._payType) : $t(`暂未支付`) }}</view>
				</view>
				<view class="item acea-row row-between-wrapper">
					<view>{{ $t(`支付金额`) }}</view>
					<view class="itemCom">{{ order_pay_info.pay_price }}</view>
				</view>
				<!--失败时加上这个  -->
				<view class="item acea-row row-between-wrapper" v-if="order_pay_info.paid == 0 && order_pay_info.pay_type != 'offline'">
					<view>{{ $t(`失败原因`) }}</view>
					<view class="itemCom">{{ $t(`未支付`) }}</view>
				</view>
			</view>
			<!--失败时： 重新购买 -->
			<view @tap="goOrderDetails" v-if="status == 0">
				<button formType="submit" class="returnBnt bg-color" hover-class="none">{{ $t(`查看订单`) }}</button>
			</view>
			<!-- #ifdef H5 -->
			<view @tap="getOrderPayInfo" v-if="order_pay_info.paid == 0">
				<button class="returnBnt bg-color" hover-class="none">{{ $t(`刷新支付状态`) }}</button>
			</view>
			<!-- #endif -->
			<view @tap="goOrderDetails" v-if="order_pay_info.paid == 0 && status == 1">
				<button class="returnBnt bg-color" hover-class="none">{{ $t(`重新购买`) }}</button>
			</view>
			<view @tap="goOrderDetails" v-if="order_pay_info.paid == 0 && status == 2">
				<button class="returnBnt bg-color" hover-class="none">{{ $t(`重新支付`) }}</button>
			</view>
			<button @click="goIndex" class="returnBnt cart-color" formType="submit" hover-class="none">{{ $t(`返回首页`) }}</button>
		</view>
	</view>
</template>

<script>
import { getOrderDetail } from '@/api/order.js';
import { openOrderSubscribe } from '@/utils/SubscribeMessage.js';
import { toLogin } from '@/libs/login.js';
import { mapGetters } from 'vuex';
import colors from '@/mixins/color';
export default {
	mixins: [colors],
	data() {
		return {
			loading: false,
			orderId: '',
			order_pay_info: {
				paid: 1,
				_status: {}
			},
			isAuto: false, //没有授权的不会自动授权
			isShowAuth: false, //是否隐藏授权
			status: 0,
			msg: '',
			options: null,
			payType: ''
		};
	},
	computed: mapGetters(['isLogin']),
	watch: {
		isLogin: {
			handler: function (newV, oldV) {
				if (newV) {
					this.getOrderPayInfo();
				}
			},
			deep: true
		}
	},
	onLoad(options) {
		this.options = options;
		if (!options.order_id)
			return this.$util.Tips(
				{
					title: this.$t(`缺少参数无法查看订单支付状态`)
				},
				{
					tab: 3,
					url: 1
				}
			);
		this.orderId = options.order_id;
		this.status = options.status || 0;
		this.msg = options.msg || '';
		this.payType = options.payType || '';

		// // #ifdef H5
		// document.addEventListener('visibilitychange', (e) => {
		// 	let state = document.visibilityState
		// 	if (state == 'hidden') {
		// 		console.log('用户离开了');
		// 	}
		// 	if (state == 'visible') {
		// 		this.getOrderPayInfo();
		// 	}
		// });
		// // #endif
	},
	onShow() {
		if (this.isLogin) {
			this.getOrderPayInfo();
		} else {
			toLogin();
		}
	},
	methods: {
		onLoadFun: function () {
			this.getOrderPayInfo();
		},
		/**
		 *
		 * 支付完成查询支付状态
		 *
		 */
		getOrderPayInfo: function () {
			let that = this;
			uni.showLoading({
				title: that.$t(`正在加载中`)
			});
			getOrderDetail(that.orderId)
				.then((res) => {
					uni.hideLoading();
					that.$set(that, 'order_pay_info', res.data);
					uni.setNavigationBarTitle({
						title: res.data.paid ? that.$t(`支付成功`) : that.$t(`未支付`)
					});
					this.loading = true;
				})
				.catch((err) => {
					this.loading = true;
					uni.hideLoading();
				});
		},
		goIndex: function (e) {
			uni.switchTab({
				url: '/pages/index/index'
			});
		},
		goOrderDetails: function (e) {
			let that = this;
			// #ifdef MP
			uni.showLoading({
				title: that.$t(`正在加载中`)
			});
			openOrderSubscribe()
				.then((res) => {
					uni.hideLoading();
					uni.redirectTo({
						url: '/pages/goods/order_details/index?order_id=' + that.orderId
					});
				})
				.catch(() => {
						uni.hideLoading();
				});
			// #endif
			// #ifndef MP
			uni.redirectTo({
				url: '/pages/goods/order_details/index?order_id=' + that.orderId
			});
			// #endif
		}
	}
};
</script>

<style lang="scss">
.payment-status {
	background-color: #fff;
	margin: 195rpx 30rpx 0 30rpx;
	border-radius: 10rpx;
	padding: 1rpx 0 28rpx 0;
}

.payment-status .icons {
	font-size: 70rpx;
	width: 140rpx;
	height: 140rpx;
	border-radius: 50%;
	color: #fff;
	text-align: center;
	line-height: 140rpx;
	text-shadow: 0px 4px 0px rgba(255, 255, 255, 0.5);
	border: 6rpx solid #f5f5f5;
	margin: -76rpx auto 0 auto;
	background-color: #999;
}

.payment-status .icons.icon-iconfontguanbi {
	text-shadow: 0px 4px 0px #6c6d6d;
}

.payment-status .iconfont.fail {
	text-shadow: 0px 4px 0px #7a7a7a;
}

.payment-status .status {
	font-size: 32rpx;
	font-weight: bold;
	text-align: center;
	margin: 25rpx 0 37rpx 0;
}

.payment-status .wrapper {
	border: 1rpx solid #eee;
	margin: 0 30rpx 47rpx 30rpx;
	padding: 35rpx 0;
	border-left: 0;
	border-right: 0;
}

.payment-status .wrapper .item {
	font-size: 28rpx;
	color: #282828;
}

.payment-status .wrapper .item ~ .item {
	margin-top: 20rpx;
}

.payment-status .wrapper .item .itemCom {
	color: #666;
}

.payment-status .returnBnt {
	width: 630rpx;
	height: 86rpx;
	border-radius: 50rpx;
	color: #fff;
	font-size: 30rpx;
	text-align: center;
	line-height: 86rpx;
	margin: 0 auto 20rpx auto;
}
</style>
