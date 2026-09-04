<template>
  <view class="product-service" v-if="!isHide">
    <commonWrapper :config="dataConfig">
      <view class="service-list">
        <!-- Activity -->
        <view
          class="item"
          v-if="checkList.includes(0) && businessActivity.length"
        >
          <view class="label" :style="{ color: titleColor }">{{
            $t("活动")
          }}</view>
          <view class="content" @click="activityTap">
            <view class="tags-wrapper">
              <!-- Activity -->
              <block v-for="(item, index) in businessActivity" :key="index">
                <view
                  class="tag-item"
                  v-if="item.type === '1'"
                  :style="tagStyle"
                  @click.stop="goActivity(item)"
                >
                  <text class="iconfont icon-miaosha1"></text>
                  {{ $t("秒杀")
                  }}<text
                    class="iconfont icon-you2"
                    :style="{ color: activityColor }"
                  ></text>
                </view>
              </block>
            </view>
            <text
              class="iconfont icon-jiantou"
              :style="{ color: contentColor }"
            ></text>
          </view>
        </view>

        <!-- Selection -->
        <view
          class="item"
          v-if="
            checkList.includes(1) && attr.productAttr && attr.productAttr.length
          "
          @click="showSpecModal"
        >
          <view class="label" :style="{ color: titleColor }">{{
            $t("选择")
          }}</view>
          <view class="content">
            <view class="text line1" :style="{ color: contentColor }">
              {{ attrTxt }}：{{ attrValue }}
            </view>
            <text
              class="iconfont icon-jiantou"
              :style="{ color: contentColor }"
            ></text>
          </view>
        </view>

        <!-- Parameters -->
        <view
          class="item"
          v-if="
            checkList.includes(2) &&
            productData.params_list &&
            productData.params_list.length
          "
          @click="openModal('specs')"
        >
          <view class="label" :style="{ color: titleColor }">{{
            $t("参数")
          }}</view>
          <view class="content">
            <view class="text line1" :style="{ color: contentColor }">
              <text
                v-for="(item, index) in productData.params_list"
                :key="index"
              >
                {{ item.name }} ·
              </text>
            </view>
            <text
              class="iconfont icon-jiantou"
              :style="{ color: contentColor }"
            ></text>
          </view>
        </view>

        <!-- Service -->
        <view
          class="item"
          v-if="
            checkList.includes(3) &&
            productData.protection_list &&
            productData.protection_list.length
          "
          @click="openModal('protection')"
        >
          <view class="label" :style="{ color: titleColor }">{{
            $t("服务")
          }}</view>
          <view class="content">
            <view class="text line1" :style="{ color: contentColor }">
              <text
                v-for="(item, index) in productData.protection_list"
                :key="index"
              >
                {{ item.title }} ·
              </text>
            </view>
            <text
              class="iconfont icon-jiantou"
              :style="{ color: contentColor }"
            ></text>
          </view>
        </view>
      </view>
    </commonWrapper>
  </view>
</template>

<script>
import commonWrapper from "./commonWrapper.vue";

export default {
  name: "homeProductService",
  components: {
    commonWrapper,
  },
  props: {
    dataConfig: {
      type: Object,
      default: () => ({}),
    },
    productData: {
      type: Object,
      default: () => ({}),
    },
    activity: {
      type: Array,
      default: () => [],
    },
    attr: {
      type: Object,
      default: () => ({}),
    },
    attrTxt: {
      type: String,
      default: "",
    },
    attrValue: {
      type: String,
      default: "",
    },
  },
  computed: {
    isHide() {
      return this.dataConfig.isHide;
    },
    checkList() {
      return this.dataConfig.checkBoxConfig
        ? this.dataConfig.checkBoxConfig.type
        : [];
    },
    businessActivity() {
      return (this.activity || []).filter((item) => item.type === "1");
    },
    titleColor() {
      return this.dataConfig.titleColor
        ? this.dataConfig.titleColor.color[0].item
        : "#999999";
    },
    contentColor() {
      return this.dataConfig.contentColor
        ? this.dataConfig.contentColor.color[0].item
        : "#333333";
    },
    isCustomTone() {
      return (
        this.dataConfig.toneConfig && this.dataConfig.toneConfig.tabVal === 1
      );
    },
    tagStyle() {
      if (this.isCustomTone) {
        const color = this.dataConfig.activityColor
          ? this.dataConfig.activityColor.color[0].item
          : "var(--view-theme)";
        const bg = this.dataConfig.activityBgColor
          ? this.dataConfig.activityBgColor.color[0].item
          : "var(--view-minorColorT)";
        return {
          color: color,
          background: bg,
        };
      }
      return {
        color: "var(--view-theme)",
        background: "var(--view-minorColorT)",
      };
    },
    activityColor() {
      if (this.isCustomTone) {
        return this.dataConfig.activityColor
          ? this.dataConfig.activityColor.color[0].item
          : "var(--view-theme)";
      }
      return "var(--view-theme)";
    },
  },
  methods: {
    activityTap() {
      if (this.businessActivity.length) this.goActivity(this.businessActivity[0]);
    },
    goActivity(item) {
      this.$emit("goActivity", item);
    },
    showSpecModal() {
      this.$emit("showSpecModal");
    },
    openModal(type) {
      this.$emit("openModal", type);
    },
  },
};
</script>

<style lang="scss" scoped>
.product-service {
  .service-list {
    .item {
      display: flex;
      align-items: center;
      padding: 28rpx 0rpx;
      position: relative;

      .label {
        width: 80rpx;
        font-size: 28rpx;
        margin-right: 20rpx;
      }

      .content {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: space-between;
        overflow: hidden;

        .text {
          font-size: 28rpx;
          color: #333;
        }

        .tags-wrapper {
          display: flex;
          flex-wrap: wrap;

          .tag-item {
            font-size: 24rpx;
            padding: 3rpx 10rpx;
            border-radius: 30rpx;
            margin-right: 10rpx;
            display: flex;
            align-items: center;
            .iconfont {
              &:first-child {
                font-size: 24rpx;
                margin-right: 5rpx;
              }
              font-size: 18rpx;
              line-height: 22rpx;
            }
          }
        }

        .iconfont {
          font-size: 24rpx;
        }
      }
    }
  }
}
</style>
