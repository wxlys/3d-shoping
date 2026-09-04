<template>
  <!-- 业务设置：仅保留成品/定制打印需要的销售与运营字段 -->
  <el-row>
    <el-col :span="24">
      <el-form-item label="起购数量：">
        <el-input-number
          :controls="false"
          :min="1"
          :max="9999999999"
          :precision="0"
          v-model="formValidate.min_qty"
          placeholder="请输入起购数量"
          class="input_width input-number-unit-class"
          :class-unit="formValidate.unit_name || '件'"
        />
      </el-form-item>
    </el-col>
    <el-col :span="24">
      <el-form-item label="是否限购：">
        <el-switch
          v-model="formValidate.is_limit"
          class="defineSwitch"
          active-text="开启"
          inactive-text="关闭"
          :active-value="1"
          :inactive-value="0"
          size="large"
        ></el-switch>
      </el-form-item>
    </el-col>
    <el-col v-if="formValidate.is_limit" :span="24">
      <el-form-item label="限购类型：">
        <el-radio-group v-model="formValidate.limit_type">
          <el-radio :label="1">单次限购</el-radio>
          <el-radio :label="2">单人限购</el-radio>
        </el-radio-group>
        <div class="tips-info">单次限购限制每次下单数量，单人限购限制用户累计购买数量。</div>
      </el-form-item>
    </el-col>
    <el-col v-if="formValidate.is_limit" :span="24">
      <el-form-item label="限购数量：">
        <el-input-number
          :controls="false"
          :min="1"
          :max="9999999999"
          :precision="0"
          v-model="formValidate.limit_num"
          placeholder="请输入限购数量"
          class="input_width input-number-unit-class"
          :class-unit="formValidate.unit_name || '件'"
        />
      </el-form-item>
    </el-col>
    <el-col :span="24">
      <div class="line"></div>
    </el-col>
    <el-col :span="24">
      <el-form-item label="商品推荐：">
        <el-checkbox-group v-model="formValidate.recommend">
          <el-checkbox label="is_hot">热卖单品</el-checkbox>
          <el-checkbox label="is_best">精品推荐</el-checkbox>
          <el-checkbox label="is_new">首发新品</el-checkbox>
          <el-checkbox label="is_good">优品推荐</el-checkbox>
        </el-checkbox-group>
      </el-form-item>
    </el-col>
    <el-col :span="24">
      <el-form-item label="活动优先级：">
        <div class="color-list acea-row row-middle">
          <div
            class="color-item"
            :class="activity[color]"
            v-for="color in formValidate.activity"
            v-dragging="{ item: color, list: formValidate.activity, group: 'color' }"
            :key="color"
          >
            {{ color }}
          </div>
        </div>
        <div class="tips-info">可拖动按钮调整默认展示和秒杀活动的优先顺序。</div>
      </el-form-item>
    </el-col>
    <el-col :span="24">
      <el-form-item label="关联推荐商品：">
        <div class="picBox">
          <div class="pictrue" v-for="(item, index) in formValidate.recommend_list" :key="index">
            <img v-lazy="item.image" />
            <i class="el-icon-error btndel" v-db-click @click="handleRemoveRecommend(index)"></i>
          </div>
          <div class="upLoad acea-row row-center-wrapper" v-db-click @click="changeGoods">
            <i class="el-icon-picture-outline" style="font-size: 24px"></i>
          </div>
        </div>
      </el-form-item>
    </el-col>
    <el-col :span="24">
      <div class="line"></div>
    </el-col>
    <el-col :span="24">
      <el-form-item label="已售数量：">
        <el-input-number
          :controls="false"
          :min="0"
          :max="9999999999"
          v-model="formValidate.ficti"
          placeholder="请输入展示销量"
          class="input_width input-number-unit-class"
          :class-unit="formValidate.unit_name || '件'"
        />
      </el-form-item>
    </el-col>
    <el-col :span="24">
      <el-form-item label="排序：">
        <el-input-number
          :controls="false"
          :min="0"
          :max="9999999999"
          v-model="formValidate.sort"
          placeholder="请输入数字，越大越靠前"
          class="input_width"
        />
      </el-form-item>
    </el-col>
  </el-row>
</template>

<script>
export default {
  name: 'BusinessSetting',
  props: {
    formValidate: {
      type: Object,
      required: true,
    },
    activity: {
      type: Object,
      default: () => ({}),
    },
  },
  methods: {
    handleRemoveRecommend(index) {
      this.$emit('handleRemoveRecommend', index);
    },
    changeGoods() {
      this.$emit('changeGoods');
    },
  },
};
</script>

<style lang="scss" scoped>
@use '../productAdd.scss' as *;
</style>
