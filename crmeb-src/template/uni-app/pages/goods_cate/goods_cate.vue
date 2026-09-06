<template>
	<view class="category-page" :style="colorStyle">
		<view class="print-service" @click="goPrintInquiry">
			<view class="print-service__content">
				<view class="print-service__title">定制打印</view>
				<view class="print-service__desc">上传模型，选择尺寸、材料和数量，获取专属报价</view>
			</view>
			<view class="print-service__action">立即询价 <text class="iconfont icon-xiangyou"></text></view>
		</view>
		<goodsCate1 v-if="category == 1" ref="classOne" :isNew="isNew"></goodsCate1>
		<goodsCate2 v-if="category == 2" ref="classTwo" :isNew="isNew" @jumpIndex="jumpIndex"></goodsCate2>
		<goodsCate3 v-if="category == 3" ref="classThree" :isNew="isNew" @jumpIndex="jumpIndex"></goodsCate3>
		<pageFooter v-if="category == 1" @newDataStatus="newDataStatus" v-show="showBar"></pageFooter>
	</view>
</template>

<script>
	import colors from "@/mixins/color";
	import goodsCate1 from "./goods_cate1";
	import goodsCate2 from "./goods_cate2";
	import goodsCate3 from "./goods_cate3";
	import {
		getThemeInfo
	} from "@/api/api.js";
	import {
		mapGetters
	} from "vuex";
	import {
		getCategoryVersion
	} from "@/api/public.js";
	import pageFooter from "@/components/pageFooter/index.vue";
	export default {
		computed: mapGetters(["isLogin", "uid"]),
		components: {
			goodsCate1,
			goodsCate2,
			goodsCate3,
			pageFooter,
		},
		mixins: [colors],
		data() {
			return {
				category: "",
				is_diy: uni.getStorageSync("is_diy"),
				status: 0,
				version: "",
				isNew: false,
				isFooter: false,
				showBar: false,
			};
		},
		onLoad() {},
		onReady() {},
		onShow() {
			this.getCategoryVersion();
		},
		onPageScroll(e) {
			console.log(e)
			uni.$emit("scroll");
		},
		methods: {
			goPrintInquiry() {
				uni.navigateTo({
					url: "/pages/print/inquiry/index",
				});
			},
			newDataStatus(val, num) {
				this.isFooter = val ? true : false;
				this.showBar = val ? true : false;
				this.pdHeight = num;
			},
			getCategoryVersion() {
				uni.$emit("uploadFooter");
				getCategoryVersion().then((res) => {
					if (
						!uni.getStorageSync("CAT_VERSION") ||
						res.data.version != uni.getStorageSync("CAT_VERSION")
					) {
						uni.setStorageSync("CAT_VERSION", res.data.version);
						uni.$emit("uploadCatData");
					}
					this.classStyle();
				});
			},
			jumpIndex() {
				uni.reLaunch({
					url: "/pages/index/index",
				});
			},
			classStyle() {
				let previewThemeId = uni.getStorageSync("previewThemeId");
				let data = {};
				if (previewThemeId) data.theme_id = previewThemeId;
				getThemeInfo("category", data).then((res) => {
					let status = res.data.status;
					this.category = status;
					uni.setStorageSync("is_diy", 1);
					this.$nextTick((e) => {
						if (status == 2 || status == 3) {
							uni.hideTabBar();
						} else {
							this.$refs.classOne.is_diy = 1;
							if (!this.is_diy) {
								uni.hideTabBar();
							} else {
								this.$refs.classOne.getNav();
							}
						}
					});
				});
			},
		},
		onReachBottom: function() {
			if (this.category == 2) {
				this.$refs.classTwo.productslist();
			}
			if (this.category == 3) {
				this.$refs.classThree.productslist();
			}
		},
	};
</script>
<style scoped lang="scss">
	.category-page {
		display: flex;
		flex-direction: column;
		height: 100vh;
		overflow: hidden;
	}

	::v-deep .productSort {
		flex: 1;
		min-height: 0;
		height: auto !important;
	}

	.print-service {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin: 24rpx;
		padding: 30rpx 28rpx;
		border-radius: 20rpx;
		color: #fff;
		background: linear-gradient(135deg, #f05a3c 0%, #e93323 100%);
		box-shadow: 0 10rpx 28rpx rgba(233, 51, 35, 0.18);
	}

	.print-service__content {
		min-width: 0;
		padding-right: 20rpx;
	}

	.print-service__title {
		font-size: 34rpx;
		font-weight: 600;
	}

	.print-service__desc {
		margin-top: 10rpx;
		font-size: 24rpx;
		line-height: 1.5;
		opacity: 0.9;
	}

	.print-service__action {
		flex: none;
		font-size: 25rpx;
		white-space: nowrap;
	}

	::v-deep.mask {
		z-index: 99;
	}

	::-webkit-scrollbar {
		width: 0;
		height: 0;
		color: transparent;
		display: none;
	}
</style>
